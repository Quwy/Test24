unit uHostForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls;

type
  TfHostForm = class(TForm)
    ProgressTimer: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ProgressTimerTimer(Sender: TObject);
  public
    Progress: LongWord;
    ProgressButtonID, HideButtonID, ProgressBarID: NativeUInt;
  end;

var
  fHostForm: TfHostForm;

implementation

{$R *.dfm}

uses
  uVidgetsDllWrapper, uVidgetSharedTypes;

procedure ButtonClick(ClassName: PWideChar; ID: NativeUInt; EventAPI: TEventAPI; WidgetProps: TWidgetProps; var UserData: Pointer); stdcall;
begin
  if ID = fHostForm.ProgressButtonID then
    if (EventAPI.EventType = etMouseUp) and (fHostForm.Progress = 0) then
      begin
        UserData := PWideChar('Clicked');

        fHostForm.ProgressTimer.Enabled := True;
      end;

  if ID = fHostForm.HideButtonID then
    CheckVidget(UpdateWidgetVisibility(ID, False));
end;

procedure ProgressBarPaintProc(ClassName: PWideChar; ID: NativeUInt; PaintAPI: TPaintAPI; WidgetProps: PWidgetProps; var UserData: Pointer); stdcall;
const
  MIN = 0;
  MAX = 100;
var
  Position, Color: LongWord;
  Len: Integer;
begin
  Position := PLongWord(UserData)^;
  Len := Trunc(((WidgetProps^.Dimensions.Width - 2) / (MAX - MIN)) * Position);

  if Position < 100 then
    Color := LongWord(clBlue)
  else
    Color := LongWord(clRed);

  PaintAPI.FillRect(WidgetProps^.Color, WidgetProps^.Dimensions.Left, WidgetProps^.Dimensions.Top, WidgetProps^.Dimensions.Left + WidgetProps^.Dimensions.Width, WidgetProps^.Dimensions.Top + WidgetProps^.Dimensions.Height);
  PaintAPI.FillRect(Color, WidgetProps^.Dimensions.Left + 1, WidgetProps^.Dimensions.Top + 1, WidgetProps^.Dimensions.Left + 1 + Len, WidgetProps^.Dimensions.Top + WidgetProps^.Dimensions.Height - 1);
  PaintAPI.OutText(LongWord(clBlack), WidgetProps^.Dimensions.Left, WidgetProps^.Dimensions.Top, WidgetProps^.Dimensions.Left + WidgetProps^.Dimensions.Width, WidgetProps^.Dimensions.Top + WidgetProps^.Dimensions.Height, PWideChar(IntToStr(Position) + '%'));
end;

procedure TfHostForm.FormCreate(Sender: TObject);
var
  PnlID, DummyID: NativeUInt;
begin
  Progress := 0;

  CheckVidget(Init(Handle));

  CheckVidget(CreateVidget('PANEL', 0, CreateWidgetProps(LongWord(clWhite), 10, 10, 300, 300), nil, nil, PnlID));
  CheckVidget(CreateVidget('LABEL', PnlID, CreateWidgetProps(LongWord(clSilver), 10, 10, 360, 20), PWideChar('Label not fit to parent'), nil, DummyID));
  CheckVidget(CreateVidget('BUTTON', PnlID, CreateWidgetProps(LongWord(clSilver), 10, 60, 100, 30), PWideChar('Start!'), ButtonClick, ProgressButtonID));
  CheckVidget(CreateVidget('BUTTON', PnlID, CreateWidgetProps(LongWord(clSilver), 10, 140, 100, 30), PWideChar('Hide me'), ButtonClick, HideButtonID));

  CheckVidget(CreateVidgetClass('PROGRESSBAR', ProgressBarPaintProc, nil));
  CheckVidget(CreateVidget('PROGRESSBAR', PnlID, CreateWidgetProps(LongWord(clSilver), 10, 100, 100, 30), @Progress, nil, ProgressBarID));
end;

procedure TfHostForm.FormDestroy(Sender: TObject);
begin
  CheckVidget(Deinit);
end;

procedure TfHostForm.ProgressTimerTimer(Sender: TObject);
begin
  if Progress < 100 then
    begin
      Inc(Progress);
      try
        CheckVidget(UpdateWidgetUserData(ProgressBarID, @Progress));
      except
        (Sender as TTimer).Enabled := False;
        raise;
      end;
    end
  else
    (Sender as TTimer).Enabled := False;
end;

end.

