unit SDUDiskPropertiesDlg;

interface

uses
  CheckLst, Classes, Controls, Dialogs, ExtCtrls, Forms,
  Graphics, Messages, SDUCheckLst,
  SDUForms, SDUGeneral, StdCtrls, SysUtils, Variants, Windows;

type
  TSDUDiskPropertiesDialog = class (TSDUForm)
    Label1:               TLabel;
    edTracksPerCylinder:  TEdit;
    pbClose:              TButton;
    Label4:               TLabel;
    Label5:               TLabel;
    Label6:               TLabel;
    Label7:               TLabel;
    edSectorsPerTrack:    TEdit;
    edBytesPerSector:     TEdit;
    edMediaType:          TEdit;
    edSizeBytes:          TEdit;
    Label11:              TLabel;
    edCylinders:          TEdit;
    edDiskNumber:         TEdit;
    Label8:               TLabel;
    edDiskSignature:      TEdit;
    Label10:              TLabel;
    edDiskPartitionCount: TEdit;
    Label12:              TLabel;
    Label2:               TLabel;
    edSizeUnits:          TEdit;
    procedure FormShow(Sender: TObject);
  PRIVATE
    { Private declarations }
  PUBLIC
    DiskNumber: Integer;
  end;

implementation

{$R *.dfm}

resourcestring
  RS_UNABLE_TO_OBTAIN_DATA = '<Unable to obtain data>';

procedure TSDUDiskPropertiesDialog.FormShow(Sender: TObject);
var
  layout:       TSDUDriveLayoutInformation;
  diskGeometry: TSDUDiskGeometry;
  size:         ULONGLONG;
begin
  edDiskNumber.Text := IntToStr(DiskNumber);

  edDiskPartitionCount.Text := RS_UNABLE_TO_OBTAIN_DATA;
  edDiskSignature.Text      := RS_UNABLE_TO_OBTAIN_DATA;
  if SDUGetDriveLayout(DiskNumber, layout) then begin
    edDiskPartitionCount.Text := IntToStr(layout.PartitionCount);
    edDiskSignature.Text      := '0x' + inttohex(layout.Signature, 8);
  end;

  edCylinders.Text         := RS_UNABLE_TO_OBTAIN_DATA;
  edTracksPerCylinder.Text := RS_UNABLE_TO_OBTAIN_DATA;
  edSectorsPerTrack.Text   := RS_UNABLE_TO_OBTAIN_DATA;
  edBytesPerSector.Text    := RS_UNABLE_TO_OBTAIN_DATA;
  edSizeBytes.Text         := RS_UNABLE_TO_OBTAIN_DATA;
  edSizeUnits.Text         := RS_UNABLE_TO_OBTAIN_DATA;
  edMediaType.Text         := RS_UNABLE_TO_OBTAIN_DATA;
  if SDUGetDiskGeometry(DiskNumber, diskGeometry) then begin
    edCylinders.Text         := IntToStr(diskGeometry.Cylinders.QuadPart);
    edTracksPerCylinder.Text := IntToStr(diskGeometry.TracksPerCylinder);
    edSectorsPerTrack.Text   := IntToStr(diskGeometry.SectorsPerTrack);
    edBytesPerSector.Text    := IntToStr(diskGeometry.BytesPerSector);
    size                     := diskGeometry.Cylinders.QuadPart *
      diskGeometry.TracksPerCylinder * diskGeometry.SectorsPerTrack * diskGeometry.BytesPerSector;
    edSizeBytes.Text         := SDUIntToStrThousands(size);
    edSizeUnits.Text         := SDUFormatAsBytesUnits(size);
    edMediaType.Text         := '0x' + inttohex(diskGeometry.MediaType, 2) +
      ': ' + TSDUMediaTypeTitle[TSDUMediaType(diskGeometry.MediaType)];
  end;

end;

end.
