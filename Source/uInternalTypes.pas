{ some data types for internal usage in the different units }

unit uInternalTypes;

interface

uses
  uVidgetSharedTypes;

type
  TGlobalPaintProc = procedure(const PaintAPI: TPaintAPI);
  TGlobalEventProc = procedure(const EventAPI: TEventAPI);

implementation

end.
