{ internal representation of the Vidgets and some other classes }

unit uVidgetsClasses;

interface

uses
  uVidgetSharedTypes,
  System.Types,
  System.Classes,
  System.SysUtils,
  System.Generics.Collections;

type
  // record for store vidget "class" declaration
  TClassHeader = record
    Name: UnicodeString; // name of the "class"
    PaintProc: TVidgetPaintProc; // Vidget paint method
    SystemEventProc: TVidgetSystemEventProc; // system event handler (used to draw some responce on the event)
    class function Create(const Name: UnicodeString; const PaintProc: TVidgetPaintProc; const EventProc: TVidgetSystemEventProc): TClassHeader; static;
  end;

type
  TChildVidget = class;

  // root pseudo-panel (stretched to whole OS window), used as parent for all bottom-level Vidgets
  // also base class for all Vidgets
  TVidget = class(TObject)
  private
    FChilds: TList<TChildVidget>; // any Vidgets can be parent, such as the modern FireMonkey framework
    procedure SetColor(const Value: Cardinal);
    function GetColor: Cardinal;
    function GetDimensions: TVidgetDimensions;
  protected
    FVidgetProps: TVidgetProps;
    procedure AddChild(const Child: TChildVidget);
    procedure RemoveChild(const Child: TChildVidget);
    procedure FreeChilds;
    function GetID: NativeUInt; virtual;
  public
    constructor Create(const Color: Cardinal; const Width, Height: LongInt);
    destructor Destroy; override;
    procedure Paint(const PaintAPI: TPaintAPI); virtual;
    function Event(const EventAPI: TEventAPI): Boolean; virtual;
    procedure NeedRepaint; virtual;
    function VidgetByID(const ID: NativeUInt): TChildVidget;

    property Color: Cardinal read GetColor write SetColor;
    property Dimensions: TVidgetDimensions read GetDimensions;
    property ID: NativeUInt read GetID;
  end;

  // Vidget class. one for all
  // look of the vidget is defined by FPaintProc handler
  // visial reaction on the events is defined by FSystemEventProc handler
  TChildVidget = class(TVidget)
  private
    FClassName: UnicodeString;
    FParent: TVidget;
    FUserData: Pointer;
    FPaintProc: TVidgetPaintProc;
    FSystemEventProc: TVidgetSystemEventProc;
    FUserEventProc: TVidgetUserEventProc; // user defined event handler (such as OnClick or OnMouseDown)
    FVisible: Boolean;
    procedure DoPaint(const PaintAPI: TPaintAPI);
    function DoEvent(const EventAPI: TEventAPI): Boolean;
    procedure SetVisible(const Value: Boolean);
    procedure NormalizeDimensions(var Dimensions: TVidgetDimensions);
  protected
    function GetVidgetProps: TVidgetProps;
    function GetID: NativeUInt; override;
  public
    constructor Create(const ClassName: string; const Parent: TVidget; const VidgetData: TVidgetProps; const PaintProc: TVidgetPaintProc; const SystemEventProc: TVidgetSystemEventProc; const UserData: Pointer);
    destructor Destroy; override;
    procedure Paint(const PaintAPI: TPaintAPI); override;
    function Event(const EventAPI: TEventAPI): Boolean; override;
    function InRange(const Point: TPoint): Boolean;

    property Vidible: Boolean read FVisible write SetVisible;
    property UserData: Pointer read FUserData write FUserData;
    property VidgetClassName: UnicodeString read FClassName;
    property Parent: TVidget read FParent;
    property UserEventProc: TVidgetUserEventProc read FUserEventProc write FUserEventProc;
  end;

  // list of idget "class" declaration records
  TClassHeaders = class(TList<TClassHeader>)
  public
    function IndexOfName(const Name: UnicodeString): Integer;
  end;

implementation

uses
  uVidgetsProcs;

{ TRootVidget }

procedure TVidget.AddChild(const Child: TChildVidget);
begin
  if FChilds.IndexOf(Child) < 0 then
    FChilds.Add(Child);
end;

constructor TVidget.Create(const Color: Cardinal; const Width, Height: LongInt);
begin
  inherited Create;

  FChilds := TList<TChildVidget>.Create;
  FVidgetProps.Color := Color;
  FVidgetProps.Dimensions.Left := 0;
  FVidgetProps.Dimensions.Top := 0;
  FVidgetProps.Dimensions.Width := Width;
  FVidgetProps.Dimensions.Height := Height;
end;

destructor TVidget.Destroy;
begin
  FreeChilds; // here will destroyed all created vidgets, so there is not needed to free them manually
  FChilds.Free;

  inherited Destroy;
end;

function TVidget.Event(const EventAPI: TEventAPI): Boolean;
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

procedure TVidget.FreeChilds;
begin
  // not so optimal, but in case of mutating FChilds during loop, is not worst solution
  while FChilds.Count > 0 do
    FChilds[0].Free;
end;

function TVidget.GetColor: Cardinal;
begin
  Result := FVidgetProps.Color;
end;

function TVidget.GetDimensions: TVidgetDimensions;
begin
  Result := FVidgetProps.Dimensions;
end;

function TVidget.GetID: NativeUInt;
begin
  Result := 0;
end;

procedure TVidget.NeedRepaint;
begin
  VgRepaint;
end;

procedure TVidget.Paint(const PaintAPI: TPaintAPI);
var
  i: Integer;
begin
  PaintAPI.FillRect(FVidgetProps.Color, 0, 0, FVidgetProps.Dimensions.Width, FVidgetProps.Dimensions.Height);

  // yes, overlapping of the vidgets is realized by sequential paint them from bottom to top
  // yes, this is may be extremally not optimal
  // yes, in the serious project needed the different solution
  for i := 0 to FChilds.Count - 1 do
    FChilds[i].Paint(PaintAPI);
end;

procedure TVidget.RemoveChild(const Child: TChildVidget);
var
  Idx: Integer;
begin
  Idx := FChilds.IndexOf(Child);
  if Idx >= 0 then
    FChilds.Delete(Idx);
end;

procedure TVidget.SetColor(const Value: Cardinal);
begin
  if Value <> FVidgetProps.Color then
    begin
      FVidgetProps.Color := Value;
      NeedRepaint;
    end;
end;

function TVidget.VidgetByID(const ID: NativeUInt): TChildVidget;
begin
  Result := TChildVidget(ID); // yes, there is some cheating, any list of persistent ID must be used in the normal project
end;

{ TChildVidget }

constructor TChildVidget.Create(const ClassName: string; const Parent: TVidget; const VidgetData: TVidgetProps; const PaintProc: TVidgetPaintProc; const SystemEventProc: TVidgetSystemEventProc; const UserData: Pointer);
begin
  inherited Create(VidgetData.Color, VidgetData.Dimensions.Width, VidgetData.Dimensions.Height);

  FClassName := UpperCase(ClassName);
  FParent := Parent;
  FVidgetProps.Dimensions.Left := Parent.Dimensions.Left + VidgetData.Dimensions.Left;
  FVidgetProps.Dimensions.Top := Parent.Dimensions.Top + VidgetData.Dimensions.Top;
  FPaintProc := PaintProc;
  FSystemEventProc := SystemEventProc;
  FUserData := UserData;
  FVisible := True;
  FUserEventProc := nil;

  FParent.AddChild(Self);
end;

destructor TChildVidget.Destroy;
begin
  FParent.RemoveChild(Self);

  inherited Destroy;
end;

function TChildVidget.DoEvent(const EventAPI: TEventAPI): Boolean;
begin
  if Assigned(FSystemEventProc) then
    begin
      FSystemEventProc(PWideChar(FClassName), ID, EventAPI, @FVidgetProps, FUserData);
      NeedRepaint;
      Result := True;
    end
  else
    Result := False;
end;

procedure TChildVidget.DoPaint(const PaintAPI: TPaintAPI);
var
  LocVidgetProps: TVidgetProps;
begin
  if Assigned(FPaintProc) then
    begin
      LocVidgetProps := FVidgetProps;
      NormalizeDimensions(LocVidgetProps.Dimensions);
      FPaintProc(PWideChar(FClassName), ID, PaintAPI, @LocVidgetProps, FUserData);
      FVidgetProps.Color := LocVidgetProps.Color;
    end;
end;

function TChildVidget.Event(const EventAPI: TEventAPI): Boolean;
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

      // if no any child under cursor is ready to handle this event, we will
      if not Result then
        Result := DoEvent(EventAPI);

      // for case of visual responce to this event
      if Result then
        NeedRepaint;
    end;
end;

function TChildVidget.GetID: NativeUInt;
begin
  Result := NativeUInt(Self); // see comment for TVidget.VidgetByID
end;

function TChildVidget.GetVidgetProps: TVidgetProps;
begin
  Result.Color := FVidgetProps.Color;
  Result.Dimensions := FVidgetProps.Dimensions;
end;

function TChildVidget.InRange(const Point: TPoint): Boolean;
begin
  Result := (Point.X >= Dimensions.Left) and (Point.X <= Dimensions.Left + FVidgetProps.Dimensions.Width) and
            (Point.Y >= Dimensions.Top) and (Point.Y <= Dimensions.Top + FVidgetProps.Dimensions.Height);
end;

procedure TChildVidget.NormalizeDimensions(var Dimensions: TVidgetDimensions);
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

procedure TChildVidget.Paint(const PaintAPI: TPaintAPI);
var
  i: Integer;
begin
  if FVisible then
    begin
      DoPaint(PaintAPI);
      // see comment for TVidget.Paint
      for i := 0 to FChilds.Count - 1 do
        FChilds[i].Paint(PaintAPI);
    end;
end;

procedure TChildVidget.SetVisible(const Value: Boolean);
begin
  if Value <> FVisible then
    begin
      FVisible := Value;
      FParent.NeedRepaint;
    end;
end;

{ TClassHeader }

class function TClassHeader.Create(const Name: UnicodeString; const PaintProc: TVidgetPaintProc; const EventProc: TVidgetSystemEventProc): TClassHeader;
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

