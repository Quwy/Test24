{ Windows-specific code only here.
  All OsXXX funtions teorethically can be realized for any platform. }

unit uWindows;

interface

uses
  uInternalTypes,
  uVidgetSharedTypes,
  Winapi.Windows,
  Winapi.Messages,
  System.Types,
  Vcl.Graphics;

function OsInitContainer(const Container: NativeUInt; const GlobalPaintProc: TGlobalPaintProc; const GlobalEventProc: TGlobalEventProc; out Width, Height: LongInt): Boolean;
function OsDeinitContainer: Boolean;
function OsContainerInitialized: Boolean;
function OsRepaintContainer: Boolean;
function OsRGB(const R, G, B: Byte): Cardinal;

implementation

var
  Window: HWND = 0;
  OldWindowProc: Pointer;
  Canvas: TCanvas;
  PaintProc: TGlobalPaintProc;
  EventProc: TGlobalEventProc;

procedure PaintAPI_Line(Color: LongWord; X1, Y1, X2, Y2: LongInt); stdcall;
begin
  Canvas.Pen.Style := psSolid;
  Canvas.Pen.Color := TColor(Color);
  Canvas.MoveTo(X1, Y1);
  Canvas.LineTo(X2, Y2);
end;

procedure PaintAPI_DrawRect(Color: LongWord; X1, Y1, X2, Y2: LongInt); stdcall;
begin
  Canvas.Pen.Style := psSolid;
  Canvas.Pen.Color := TColor(Color);
  Canvas.Brush.Style := bsClear;
  Canvas.Rectangle(X1, Y1, X2, Y2);
end;

procedure PaintAPI_FillRect(Color: LongWord; X1, Y1, X2, Y2: LongInt); stdcall;
begin
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := TColor(Color);
  Canvas.FillRect(TRect.Create(X1, Y1, X2, Y2));
end;

procedure PaintAPI_OutText(Color: LongWord; X1, Y1, X2, Y2: LongInt; Text: PWideChar); stdcall;
var
  sText: UnicodeString;
  X, Y: Integer;
begin
  sText := string(Text);

  X := X1 + ((X2 - X1 - Canvas.TextWidth(sText)) div 2);
  Y := Y1 + ((Y2 - Y1 - Canvas.TextHeight(sText)) div 2);

  Canvas.Pen.Style := psSolid;
  Canvas.Pen.Color := TColor(Color);
  Canvas.Brush.Style := bsClear;
  Canvas.TextRect(Rect(X1, Y1, X2, Y2), X, Y, sText);
end;

function CreatePaintAPI(const DC: HDC): TPaintAPI;
begin
  Canvas := TCanvas.Create;
  Canvas.Handle := DC;

  Result.Line := PaintAPI_Line;
  Result.DrawRect := PaintAPI_DrawRect;
  Result.FillRect := PaintAPI_FillRect;
  Result.OutText := PaintAPI_OutText;
end;

procedure FreePaintAPI;
begin
  Canvas.Free;
end;

function LocWindowProc(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
var
  DC: HDC;
  PaintStruct: TPaintStruct;
  PaintAPI: TPaintAPI;
  EventAPI: TEventAPI;
begin
  case uMsg of
    WM_PAINT:
      begin
        DC := BeginPaint(hWnd, PaintStruct);
        try
          PaintAPI := CreatePaintAPI(DC);
          try
            PaintProc(PaintAPI);
          finally
            FreePaintAPI;
          end;
        finally
          EndPaint(hWnd, PaintStruct);
        end;
      end;
    WM_LBUTTONDOWN:
      begin
        EventAPI.EventType := etMouseDn;
        EventAPI.Position.X := LoWord(Cardinal(lParam));
        EventAPI.Position.Y := HiWord(Cardinal(lParam));
        EventProc(EventAPI);
      end;
    WM_LBUTTONUP:
      begin
        EventAPI.EventType := etMouseUp;
        EventAPI.Position.X := LoWord(Cardinal(lParam));
        EventAPI.Position.Y := HiWord(Cardinal(lParam));
        EventProc(EventAPI);
      end;
  end;

  Result := CallWindowProc(OldWindowProc, hWnd, uMsg, wParam, lParam);
end;

function OsInitContainer(const Container: NativeUInt; const GlobalPaintProc: TGlobalPaintProc; const GlobalEventProc: TGlobalEventProc; out Width, Height: LongInt): Boolean;
var
  Rect: TRect;
begin
  OldWindowProc := Pointer(GetWindowLongPtr(HWND(Container), GWLP_WNDPROC));
  if Assigned(OldWindowProc) then
    begin
      PaintProc := GlobalPaintProc;
      EventProc := GlobalEventProc;

      if (SetWindowLongPtr(HWND(Container), GWLP_WNDPROC, NativeInt(@LocWindowProc)) <> 0) and GetWindowRect(HWND(Container), Rect) then
        begin
          Window := HWND(Container);

          Width := Rect.Width;
          Height := Rect.Height;

          Result := True;
        end
      else
        Result := False;
    end
  else
    Result := False;
end;

function OsDeinitContainer: Boolean;
begin
  if OsContainerInitialized then
    begin
      SetWindowLongPtr(Window, GWLP_WNDPROC, NativeInt(OldWindowProc));
      RedrawWindow(Window, nil, 0, RDW_INVALIDATE);

      Window := 0;
      Result := True;
    end
  else
    Result := False;
end;

function OsContainerInitialized: Boolean;
begin
  Result := (Window <> 0);
end;

function OsRGB(const R, G, B: Byte): Cardinal;
begin
  Result := RGB(R, G, B);
end;

function OsRepaintContainer: Boolean;
begin
  if OsContainerInitialized then
    Result := RedrawWindow(Window, nil, 0, RDW_INVALIDATE)
  else
    Result := False;
end;

end.

