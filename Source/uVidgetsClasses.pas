unit uVidgetsClasses;

interface

uses
  uVidgetSharedTypes,
  System.Types,
  System.Classes,
  System.SysUtils,
  System.Generics.Collections;

type
  TClassHeader = record
    Name: UnicodeString;
    PaintProc: TWidgetPaintProc;
    SystemEventProc: TWidgetSystemEventProc;
    class function Create(const Name: UnicodeString; const PaintProc: TWidgetPaintProc; const EventProc: TWidgetSystemEventProc): TClassHeader; static;
  end;

type
  TChildWidget = class;

  TWidget = class(TObject)
  private
    FChilds: TList<TChildWidget>;
    procedure SetColor(const Value: Cardinal);
    function GetColor: Cardinal;
    function GetDimensions: TWidgetDimensions;
  protected
    FWidgetProps: TWidgetProps;
    procedure AddChild(const Child: TChildWidget);
    procedure RemoveChild(const Child: TChildWidget);
    procedure FreeChilds;
    function GetID: NativeUInt; virtual;
  public
    constructor Create(const Color: Cardinal; const Width, Height: LongInt);
    destructor Destroy; override;
    procedure Paint(const PaintAPI: TPaintAPI); virtual;
    function Event(const EventAPI: TEventAPI): Boolean; virtual;
    procedure NeedRepaint; virtual;
    function WidgetByID(const ID: NativeUInt): TChildWidget;

    property Color: Cardinal read GetColor write SetColor;
    property Dimensions: TWidgetDimensions read GetDimensions;
    property ID: NativeUInt read GetID;
  end;

  TChildWidget = class(TWidget)
  private
    FClassName: UnicodeString;
    FParent: TWidget;
    FUserData: Pointer;
    FPaintProc: TWidgetPaintProc;
    FSystemEventProc: TWidgetSystemEventProc;
    FUserEventProc: TWidgetUserEventProc;
    FVisible: Boolean;
    procedure DoPaint(const PaintAPI: TPaintAPI);
    function DoEvent(const EventAPI: TEventAPI): Boolean;
    procedure SetVisible(const Value: Boolean);
    procedure NormalizeDimensions(var Dimensions: TWidgetDimensions);
  protected
    function GetWidgetData: TWidgetProps;
    function GetID: NativeUInt; override;
  public
    constructor Create(const ClassName: string; const Parent: TWidget; const WidgetData: TWidgetProps; const PaintProc: TWidgetPaintProc; const SystemEventProc: TWidgetSystemEventProc; const UserData: Pointer);
    destructor Destroy; override;
    procedure Paint(const PaintAPI: TPaintAPI); override;
    function Event(const EventAPI: TEventAPI): Boolean; override;
    function InRange(const Point: TPoint): Boolean;

    property Vidible: Boolean read FVisible write SetVisible;
    property UserData: Pointer read FUserData write FUserData;
    property WidgetClassName: UnicodeString read FClassName;
    property Parent: TWidget read FParent;
    property UserEventProc: TWidgetUserEventProc read FUserEventProc write FUserEventProc;
  end;

  TClassHeaders = class(TList<TClassHeader>)
  public
    function IndexOfName(const Name: UnicodeString): Integer;
  end;

implementation

uses
  uVidgetsProcs;

{ TRootWidget }

procedure TWidget.AddChild(const Child: TChildWidget);
begin
  if FChilds.IndexOf(Child) < 0 then
    FChilds.Add(Child);
end;

constructor TWidget.Create(const Color: Cardinal; const Width, Height: LongInt);
begin
  inherited Create;

  FChilds := TList<TChildWidget>.Create;
  FWidgetProps.Color := Color;
  FWidgetProps.Dimensions.Left := 0;
  FWidgetProps.Dimensions.Top := 0;
  FWidgetProps.Dimensions.Width := Width;
  FWidgetProps.Dimensions.Height := Height;
end;

destructor TWidget.Destroy;
begin
  FreeChilds;
  FChilds.Free;

  inherited Destroy;
end;

function TWidget.Event(const EventAPI: TEventAPI): Boolean;
var
  i: Integer;
begin
  Result := False;

  i := FChilds.Count - 1;
  while i >= 0 do
    if FChilds[i].InRange(EventAPI.Position) and FChilds[i].Event(EventAPI) then
      begin
        i := -1;
        Result := True;
      end
    else
      Dec(i);
end;

procedure TWidget.FreeChilds;
begin
  while FChilds.Count > 0 do
    FChilds[0].Free;
end;

function TWidget.GetColor: Cardinal;
begin
  Result := FWidgetProps.Color;
end;

function TWidget.GetDimensions: TWidgetDimensions;
begin
  Result := FWidgetProps.Dimensions;
end;

function TWidget.GetID: NativeUInt;
begin
  Result := 0;
end;

procedure TWidget.NeedRepaint;
begin
  VgRepaint;
end;

procedure TWidget.Paint(const PaintAPI: TPaintAPI);
var
  i: Integer;
begin
  PaintAPI.FillRect(FWidgetProps.Color, 0, 0, FWidgetProps.Dimensions.Width, FWidgetProps.Dimensions.Height);
  for i := 0 to FChilds.Count - 1 do
    FChilds[i].Paint(PaintAPI);
end;

procedure TWidget.RemoveChild(const Child: TChildWidget);
var
  Idx: Integer;
begin
  Idx := FChilds.IndexOf(Child);
  if Idx >= 0 then
    FChilds.Delete(Idx);
end;

procedure TWidget.SetColor(const Value: Cardinal);
begin
  if Value <> FWidgetProps.Color then
    begin
      FWidgetProps.Color := Value;
      NeedRepaint;
    end;
end;

function TWidget.WidgetByID(const ID: NativeUInt): TChildWidget;
begin
  Result := TChildWidget(ID);
end;

{ TChildWidget }

constructor TChildWidget.Create(const ClassName: string; const Parent: TWidget; const WidgetData: TWidgetProps; const PaintProc: TWidgetPaintProc; const SystemEventProc: TWidgetSystemEventProc; const UserData: Pointer);
begin
  inherited Create(WidgetData.Color, WidgetData.Dimensions.Width, WidgetData.Dimensions.Height);

  FClassName := UpperCase(ClassName);
  FParent := Parent;
  FWidgetProps.Dimensions.Left := Parent.Dimensions.Left + WidgetData.Dimensions.Left;
  FWidgetProps.Dimensions.Top := Parent.Dimensions.Top + WidgetData.Dimensions.Top;
  FPaintProc := PaintProc;
  FSystemEventProc := SystemEventProc;
  FUserData := UserData;
  FVisible := True;
  FUserEventProc := nil;

  FParent.AddChild(Self);
end;

destructor TChildWidget.Destroy;
begin
  FParent.RemoveChild(Self);

  inherited Destroy;
end;

function TChildWidget.DoEvent(const EventAPI: TEventAPI): Boolean;
begin
  if Assigned(FSystemEventProc) then
    begin
      FSystemEventProc(PWideChar(FClassName), ID, EventAPI, @FWidgetProps, FUserData);
      NeedRepaint;
      Result := True;
    end
  else
    Result := False;
end;

procedure TChildWidget.DoPaint(const PaintAPI: TPaintAPI);
var
  LocWidgetProps: TWidgetProps;
begin
  if Assigned(FPaintProc) then
    begin
      LocWidgetProps := FWidgetProps;
      NormalizeDimensions(LocWidgetProps.Dimensions);
      FPaintProc(PWideChar(FClassName), ID, PaintAPI, @LocWidgetProps, FUserData);
      FWidgetProps.Color := LocWidgetProps.Color;
    end;
end;

function TChildWidget.Event(const EventAPI: TEventAPI): Boolean;
var
  i: Integer;
begin
  Result := False;

  if FVisible then
    begin
      i := FChilds.Count - 1;
      while i >= 0 do
        if FChilds[i].InRange(EventAPI.Position) and FChilds[i].Event(EventAPI) then
          begin
            i := -1;
            Result := True;
          end
        else
          Dec(i);

      if not Result then
        Result := DoEvent(EventAPI);

      if Result then
        NeedRepaint;
    end;
end;

function TChildWidget.GetID: NativeUInt;
begin
  Result := NativeUInt(Self);
end;

function TChildWidget.GetWidgetData: TWidgetProps;
begin
  Result.Color := FWidgetProps.Color;
  Result.Dimensions := FWidgetProps.Dimensions;
end;

function TChildWidget.InRange(const Point: TPoint): Boolean;
var
  AbsoluteLeft, AbsoluteTop: Integer;
  NextParent: TWidget;
begin
  AbsoluteLeft := Dimensions.Left;
  AbsoluteTop := Dimensions.Top;

  NextParent := FParent;
  while NextParent is TChildWidget do
    begin
      Inc(AbsoluteLeft, NextParent.Dimensions.Left);
      Inc(AbsoluteTop, NextParent.Dimensions.Top);
      NextParent := TChildWidget(NextParent).Parent;
    end;

  Result := (Point.X >= AbsoluteLeft) and (Point.X <= AbsoluteLeft + FWidgetProps.Dimensions.Width) and
            (Point.Y >= AbsoluteTop) and (Point.Y <= AbsoluteTop + FWidgetProps.Dimensions.Height);
end;

procedure TChildWidget.NormalizeDimensions(var Dimensions: TWidgetDimensions);
begin
  if Dimensions.Left < Parent.Dimensions.Left then
    Dimensions.Left := Parent.Dimensions.Left;
  if Dimensions.Top < Parent.Dimensions.Top then
    Dimensions.Top := Parent.Dimensions.Top;
  if Dimensions.Left + Dimensions.Width > Parent.Dimensions.Left + Parent.Dimensions.Width then
    Dimensions.Width := Parent.Dimensions.Width - Parent.Dimensions.Left;
  if Dimensions.Top + Dimensions.Height > Parent.Dimensions.Top + Parent.Dimensions.Height then
    Dimensions.Height := Parent.Dimensions.Height - Parent.Dimensions.Top;
end;

procedure TChildWidget.Paint(const PaintAPI: TPaintAPI);
var
  i: Integer;
begin
  if FVisible then
    begin
      DoPaint(PaintAPI);
      for i := 0 to FChilds.Count - 1 do
        FChilds[i].Paint(PaintAPI);
    end;
end;

procedure TChildWidget.SetVisible(const Value: Boolean);
begin
  if Value <> FVisible then
    begin
      FVisible := Value;
      FParent.NeedRepaint;
    end;
end;

{ TClassHeader }

class function TClassHeader.Create(const Name: UnicodeString; const PaintProc: TWidgetPaintProc; const EventProc: TWidgetSystemEventProc): TClassHeader;
begin
  Result.Name := UpperCase(Name);
  Result.PaintProc := PaintProc;
  Result.SystemEventProc := EventProc;
end;

{ TClassHeaders }

function TClassHeaders.IndexOfName(const Name: UnicodeString): Integer;
var
  i: Integer;
begin
  Result := -1;

  i := Count - 1;
  while i >= 0 do
    if SameText(Name, Items[i].Name) then
      begin
        Result := i;
        i := -1;
      end
    else
      Dec(i);
end;

end.

