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
    ProgressButtonID, HidePanelID, HideButtonID, ProgressBarID: NativeUInt;
  end;

var
  fHostForm: TfHostForm;

implementation

{$R *.dfm}

uses
  uVidgetsDllWrapper, uVidgetSharedTypes;

// general handler for all buttons, but it is not mandatory, separate handlers also fully allowed
procedure ButtonClick(ClassName: PWideChar; ID: NativeUInt; EventAPI: TEventAPI; WidgetProps: TWidgetProps; var UserData: Pointer); stdcall;
begin
  // handle events for button "Start!"
  if ID = fHostForm.ProgressButtonID then
    if (EventAPI.EventType = etMouseUp) and (fHostForm.Progress = 0) then
      begin
        UserData := PWideChar('Clicked');

        fHostForm.ProgressTimer.Enabled := True;
      end;

  // handle events for button "Hide my parent"
  if (ID = fHostForm.HideButtonID) and (EventAPI.EventType = etMouseUp) then
    VidgetCheck(UpdateWidgetVisibility(fHostForm.HidePanelID, False));
end;

// custom PROGRESSBAR vidget painter
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

  // initilaising surface
  VidgetCheck(Init(Handle));

  // creating some standart vidgets
  VidgetCheck(CreateVidget('PANEL', 0, CreateWidgetProps(LongWord(clWhite), 10, 10, 300, 300), nil, nil, PnlID));
  VidgetCheck(CreateVidget('LABEL', PnlID, CreateWidgetProps(LongWord(clSilver), 10, 10, 360, 20), PWideChar('Label not fit to parent'), nil, DummyID));
  VidgetCheck(CreateVidget('BUTTON', PnlID, CreateWidgetProps(LongWord(clSilver), 10, 60, 100, 30), PWideChar('Start!'), ButtonClick, ProgressButtonID));

  // creating some standart vidgets
  VidgetCheck(CreateVidget('PANEL', PnlID, CreateWidgetProps(LongWord(clDkGray), 10, 210, 200, 70), nil, nil, HidePanelID));
  VidgetCheck(CreateVidget('BUTTON', HidePanelID, CreateWidgetProps(LongWord(clSilver), 10, 10, 120, 30), PWideChar('Hide my parent'), ButtonClick, HideButtonID));

  // defining new vidget type
  VidgetCheck(CreateVidgetClass('PROGRESSBAR', ProgressBarPaintProc, nil));

  // creating some user-defined vidget and test label near it
  VidgetCheck(CreateVidget('PROGRESSBAR', PnlID, CreateWidgetProps(LongWord(clSilver), 10, 100, 100, 30), @Progress, nil, ProgressBarID));
  VidgetCheck(CreateVidget('LABEL', PnlID, CreateWidgetProps(LongWord(clWhite), 120, 105, 120, 20), PWideChar('(custom progress bar)'), nil, DummyID));
end;

procedure TfHostForm.FormDestroy(Sender: TObject);
begin
  VidgetCheck(Deinit);
end;

procedure TfHostForm.ProgressTimerTimer(Sender: TObject);
begin
  if Progress < 100 then
    begin
      Inc(Progress);
      try
        // updating progress
        VidgetCheck(UpdateWidgetUserData(ProgressBarID, @Progress));
      except
        (Sender as TTimer).Enabled := False;
        raise;
      end;
    end
  else
    (Sender as TTimer).Enabled := False;
end;

end.

