unit OTFEFreeOTFE_frmKeyEntryLUKS;
 // Description:
 // By Sarah Dean
 // Email: sdean12@sdean12.org
 // WWW:   http://www.SDean12.org/
 //
 // -----------------------------------------------------------------------------
 //


interface

uses
  Classes, ComCtrls, Controls, Dialogs,
  ExtCtrls, Forms, Graphics, Messages, OTFEFreeOTFE_U, PasswordRichEdit, SDUForms,
  Spin64,
  StdCtrls, SysUtils, Windows, // Required for TFreeOTFEMountAs
  OTFEFreeOTFE_DriverAPI, OTFEFreeOTFE_PasswordRichEdit, OTFEFreeOTFEBase_U,
  SDUFrames,
  SDUSpin64Units, SDUStdCtrls,  // Required for TFreeOTFESectorIVGenMethod and NULL_GUID
  OTFEFreeOTFE_LUKSKeyOrKeyfileEntry, SDUDropFiles, SDUFilenameEdit_U, SDUGeneral;

type
  TfrmKeyEntryLUKS = class (TSDUForm)
    pbCancel:                           TButton;
    pbOK:                               TButton;
    GroupBox2:                          TGroupBox;
    lblDrive:                           TLabel;
    lblMountAs:                         TLabel;
    cbDrive:                            TComboBox;
    ckMountReadonly:                    TSDUCheckBox;
    cbMediaType:                        TComboBox;
    GroupBox4:                          TGroupBox;
    Label10:                            TLabel;
    Label22:                            TLabel;
    GroupBox1:                          TGroupBox;
    Label1:                             TLabel;
    ckBaseIVCypherOnHashLength:         TSDUCheckBox;
    ckMountForAllUsers:                 TSDUCheckBox;
    se64UnitSizeLimit:                  TSDUSpin64Unit_Storage;
    OTFEFreeOTFELUKSKeyOrKeyfileEntry1: TOTFEFreeOTFELUKSKeyOrKeyfileEntry;
    procedure FormCreate(Sender: TObject);
    procedure pbOKClick(Sender: TObject);
    procedure SelectionChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure preUserkeyKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure pbCancelClick(Sender: TObject);
    procedure ckSelected(Sender: TObject);
  PRIVATE
  PROTECTED
    // These are ordered lists corresponding to the items shown in the combobox
    fHashKernelModeDriverNames:   TStringList;
    fHashGUIDs:                   TStringList;
    fCypherKernelModeDriverNames: TStringList;
    fCypherGUIDs:                 TStringList;

    procedure PopulateDrives();
    procedure PopulateMountAs();

    procedure DefaultOptions();

    procedure EnableDisableControls();

    procedure DoCancel();

  PUBLIC
    fFreeOTFEObj: TOTFEFreeOTFEBase;

    procedure Initialize();

    // Key...
    function GetKey(var userKey: PasswordString): Boolean;
    function SetKey(userKey: PasswordString): Boolean;
    function SetKeyfile(filename: String): Boolean;
    function GetKeyfileIsASCII(var isASCII: Boolean): Boolean;
    function SetKeyfileIsASCII(isASCII: Boolean): Boolean;
    function GetKeyfileNewlineType(var nlType: TSDUNewline): Boolean;
    function SetKeyfileNewlineType(nlType: TSDUNewline): Boolean;

    function GetIVCypherBase(var baseIVCypherOnHashLength: Boolean): Boolean;
    function SetIVCypherBase(baseIVCypherOnHashLength: Boolean): Boolean;

    // File options...
    function GetSizeLimit(var fileOptSizeLimit: Int64): Boolean;
    function SetSizeLimit(fileOptSizeLimit: Int64): Boolean;

    // Mount options...
    function GetDriveLetter(var mountDriveLetter: ansichar): Boolean;
    function SetDriveLetter(mountDriveLetter: ansichar): Boolean;
    function GetReadonly(var mountReadonly: Boolean): Boolean;
    function SetReadonly(mountReadonly: Boolean): Boolean;
    function GetMountAs(var mountAs: TFreeOTFEMountAs): Boolean;
    function SetMountAs(mountAs: TFreeOTFEMountAs): Boolean;
    function GetMountForAllUsers(): Boolean;
    procedure SetMountForAllUsers(allUsers: Boolean);
  end;


implementation

{$R *.DFM}


uses
  ComObj,                      // Required for StringToGUID
  OTFEFreeOTFE_VolumeFileAPI,  // Required for SCTRIVGEN_USES_SECTOR_ID and SCTRIVGEN_USES_HASH
  INIFiles, OTFEFreeOTFEDLL_U,
  SDUDialogs,
  SDUi18n;

procedure TfrmKeyEntryLUKS.FormCreate(Sender: TObject);
begin
  fhashKernelModeDriverNames   := TStringList.Create();
  fhashGUIDs                   := TStringList.Create();
  fcypherKernelModeDriverNames := TStringList.Create();
  fcypherGUIDs                 := TStringList.Create();

end;


procedure TfrmKeyEntryLUKS.PopulateDrives();
var
  driveLetters: Ansistring;
  i:            Integer;
begin
  cbDrive.Items.Clear();
  cbDrive.Items.Add(_('Use default'));
  driveLetters := SDUGetUnusedDriveLetters();
  for i := 1 to length(driveLetters) do begin
    // Skip the drive letters traditionally reserved for floppy disk drives
    //    if (
    //        (driveLetters[i] <> 'A') AND
    //        (driveLetters[i] <> 'B')
    //       ) then
    //      begin
    cbDrive.Items.Add(driveLetters[i] + ':');
    //      end;
  end;

end;


procedure TfrmKeyEntryLUKS.PopulateMountAs();
var
  currMountAs: TFreeOTFEMountAs;
begin
  cbMediaType.Items.Clear();
  for currMountAs := low(TFreeOTFEMountAs) to high(TFreeOTFEMountAs) do begin
    if (currMountAs <> fomaUnknown) then begin
      cbMediaType.Items.Add(FreeOTFEMountAsTitle(currMountAs));
    end;

  end;

end;

procedure TfrmKeyEntryLUKS.DefaultOptions();
var
  i:               Integer;
  currDriveLetter: ansichar;
begin
  OTFEFreeOTFELUKSKeyOrKeyfileEntry1.DefaultOptions();

  if (fFreeOTFEObj is TOTFEFreeOTFE) then begin
    if (cbDrive.Items.Count > 0) then begin
      cbDrive.ItemIndex := 0;

      if (TOTFEFreeOTFE(fFreeOTFEObj).DefaultDriveLetter <> #0) then begin
        // Start from 1; skip the default
        for i := 1 to (cbDrive.items.Count - 1) do begin
          currDriveLetter := ansichar(cbDrive.Items[i][1]);
          if (currDriveLetter >= TOTFEFreeOTFE(fFreeOTFEObj).DefaultDriveLetter) then begin
            cbDrive.ItemIndex := i;
            break;
          end;
        end;
      end;
    end;
  end;

  if (fFreeOTFEObj is TOTFEFreeOTFE) then begin
    SetMountAs(TOTFEFreeOTFE(fFreeOTFEObj).DefaultMountAs);
  end else begin
    SetMountAs(fomaFixedDisk);
  end;

  ckBaseIVCypherOnHashLength.Checked := True;

  se64UnitSizeLimit.Value := 0;

  // Default to TRUE to allow formatting under Windows Vista
  ckMountForAllUsers.Checked := True;

end;


procedure TfrmKeyEntryLUKS.pbOKClick(Sender: TObject);
var
  tmpKey:        PasswordString;
  msgZeroLenKey: String;
begin
  if GetKey(tmpKey) then begin
    if (Length(tmpKey) = 0) then begin
      if OTFEFreeOTFELUKSKeyOrKeyfileEntry1.KeyIsUserEntered() then begin
        msgZeroLenKey := _('You have not entered a password.');
      end else begin
        msgZeroLenKey := _('Keyfile contained a zero-length key.');
      end;

      if (SDUMessageDlg(msgZeroLenKey + SDUCRLF + SDUCRLF +
        _('Are you sure you wish to proceed?'), mtConfirmation,
        [mbYes, mbNo], 0) = mrYes) then begin
        ModalResult := mrOk;
      end;
    end else begin
      // No problems with the password as entered; OK to close the dialog
      ModalResult := mrOk;
    end;

  end  // if GetKey(tmpKey) then
  else begin
    if not (OTFEFreeOTFELUKSKeyOrKeyfileEntry1.KeyIsUserEntered()) then begin
      SDUMessageDlg(_('Unable to read keyfile.'), mtError);
    end;

  end;

end;


procedure TfrmKeyEntryLUKS.EnableDisableControls();
var
  junkInt64:  Int64;
  junkChar:   ansichar;
  mountAsOK:  Boolean;
  tmpMountAs: TFreeOTFEMountAs;
begin
  // Ensure we know what to mount as
  mountAsOK               := GetMountAs(tmpMountAs);
  ckMountReadonly.Enabled := False;
  if (mountAsOK) then begin
    if not (FreeOTFEMountAsCanWrite[tmpMountAs]) then begin
      ckMountReadonly.Checked := True;
    end;
    SDUEnableControl(ckMountReadonly, FreeOTFEMountAsCanWrite[tmpMountAs]);
  end;
  mountAsOK := mountAsOK and (tmpMountAs <> fomaUnknown);

  pbOK.Enabled := ((GetSizeLimit(junkInt64)) and
    (GetDriveLetter(junkChar)) and
    mountAsOK);

end;

procedure TfrmKeyEntryLUKS.SelectionChange(Sender: TObject);
begin
  EnableDisableControls();

end;

procedure TfrmKeyEntryLUKS.FormShow(Sender: TObject);
begin
  // Position cursor to the *end* of any password
  OTFEFreeOTFELUKSKeyOrKeyfileEntry1.CursorToEndOfPassword();

  // Certain controls only visble if used in conjunction with drive mounting
  lblDrive.Visible           := fFreeOTFEObj is TOTFEFreeOTFE;
  cbDrive.Visible            := fFreeOTFEObj is TOTFEFreeOTFE;
  lblMountAs.Visible         := fFreeOTFEObj is TOTFEFreeOTFE;
  cbMediaType.Visible        := fFreeOTFEObj is TOTFEFreeOTFE;
  ckMountForAllUsers.Visible := fFreeOTFEObj is TOTFEFreeOTFE;

  // Prevent making remaining control look odd, stuck in the middle
  if not (fFreeOTFEObj is TOTFEFreeOTFE) then begin
    ckMountReadonly.top  := lblDrive.top;
    ckMountReadonly.left := lblDrive.left;
  end;

  EnableDisableControls();

end;


procedure TfrmKeyEntryLUKS.FormDestroy(Sender: TObject);
begin
  fhashKernelModeDriverNames.Free();
  fhashGUIDs.Free();
  fcypherKernelModeDriverNames.Free();
  fcypherGUIDs.Free();

end;

procedure TfrmKeyEntryLUKS.preUserkeyKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (key = 27) then begin
    DoCancel();
  end;

end;

procedure TfrmKeyEntryLUKS.pbCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;

end;


procedure TfrmKeyEntryLUKS.DoCancel();
begin
  ModalResult := mrCancel;

end;


function TfrmKeyEntryLUKS.GetIVCypherBase(var baseIVCypherOnHashLength: Boolean): Boolean;
begin
  baseIVCypherOnHashLength := ckBaseIVCypherOnHashLength.Checked;
  Result                   := True;
end;

function TfrmKeyEntryLUKS.SetIVCypherBase(baseIVCypherOnHashLength: Boolean): Boolean;
begin
  ckBaseIVCypherOnHashLength.Checked := baseIVCypherOnHashLength;
  Result                             := True;
end;


function TfrmKeyEntryLUKS.GetKey(var userKey: PasswordString): Boolean;
begin
  Result := OTFEFreeOTFELUKSKeyOrKeyfileEntry1.GetKey(userKey);
end;

function TfrmKeyEntryLUKS.SetKey(userKey: PasswordString): Boolean;
begin
  Result := OTFEFreeOTFELUKSKeyOrKeyfileEntry1.SetKey(userKey);
end;

function TfrmKeyEntryLUKS.SetKeyfile(filename: String): Boolean;
begin
  Result := OTFEFreeOTFELUKSKeyOrKeyfileEntry1.SetKeyfile(filename);
end;

function TfrmKeyEntryLUKS.GetKeyfileIsASCII(var isASCII: Boolean): Boolean;
begin
  Result := OTFEFreeOTFELUKSKeyOrKeyfileEntry1.GetKeyfileIsASCII(isASCII);
end;

function TfrmKeyEntryLUKS.SetKeyfileIsASCII(isASCII: Boolean): Boolean;
begin
  Result := OTFEFreeOTFELUKSKeyOrKeyfileEntry1.SetKeyfileIsASCII(isASCII);
end;

function TfrmKeyEntryLUKS.GetKeyfileNewlineType(var nlType: TSDUNewline): Boolean;
begin
  Result := OTFEFreeOTFELUKSKeyOrKeyfileEntry1.GetKeyfileNewlineType(nlType);
end;

function TfrmKeyEntryLUKS.SetKeyfileNewlineType(nlType: TSDUNewline): Boolean;
begin
  Result := OTFEFreeOTFELUKSKeyOrKeyfileEntry1.SetKeyfileNewlineType(nlType);
end;


function TfrmKeyEntryLUKS.GetSizeLimit(var fileOptSizeLimit: Int64): Boolean;
begin
  fileOptSizeLimit := se64UnitSizeLimit.Value;
  Result           := True;
end;

function TfrmKeyEntryLUKS.SetSizeLimit(fileOptSizeLimit: Int64): Boolean;
begin
  se64UnitSizeLimit.Value := fileOptSizeLimit;
  Result                  := True;
end;

// Note: This may return #0 as mountDriveLetter to indicate "any"
function TfrmKeyEntryLUKS.GetDriveLetter(var mountDriveLetter: ansichar): Boolean;
begin
  mountDriveLetter := #0;
  // Note: The item at index zero is "Use default"; #0 is returned for this
  if (cbDrive.ItemIndex > 0) then begin
    mountDriveLetter := ansichar(cbDrive.Items[cbDrive.ItemIndex][1]);
  end;

  Result := True;
end;

// mountDriveLetter - Set to #0 to indicate "Use default"
function TfrmKeyEntryLUKS.SetDriveLetter(mountDriveLetter: ansichar): Boolean;
var
  idx:    Integer;
  retVal: Boolean;
begin
  retVal := True;

  if (mountDriveLetter = #0) then begin
    // The item at idx 0 will *always* be "Use default"
    idx := 0;
  end else begin
    idx := cbDrive.Items.IndexOf(mountDriveLetter + ':');
  end;

  if (idx < 0) then begin
    idx    := 0;
    retVal := False;
  end;
  cbDrive.ItemIndex := idx;

  Result := retVal;
end;

function TfrmKeyEntryLUKS.GetReadonly(var mountReadonly: Boolean): Boolean;
begin
  mountReadonly := ckMountReadonly.Checked;
  Result        := True;
end;

function TfrmKeyEntryLUKS.SetReadonly(mountReadonly: Boolean): Boolean;
begin
  ckMountReadonly.Checked := mountReadonly;
  Result                  := True;
end;

function TfrmKeyEntryLUKS.GetMountAs(var mountAs: TFreeOTFEMountAs): Boolean;
var
  currMountAs: TFreeOTFEMountAs;
  allOK:       Boolean;
begin
  allOK := False;

  for currMountAs := low(TFreeOTFEMountAs) to high(TFreeOTFEMountAs) do begin
    if (cbMediaType.Items[cbMediaType.ItemIndex] = FreeOTFEMountAsTitle(currMountAs)) then begin
      mountAs := currMountAs;
      allOK   := True;
      break;
    end;
  end;

  Result := allOK;
end;


function TfrmKeyEntryLUKS.SetMountAs(mountAs: TFreeOTFEMountAs): Boolean;
var
  idx:   Integer;
  allOK: Boolean;
begin
  idx                   := cbMediaType.Items.IndexOf(FreeOTFEMountAsTitle(mountAs));
  cbMediaType.ItemIndex := idx;

  allOK := (idx >= 0);

  Result := allOK;
end;


procedure TfrmKeyEntryLUKS.SetMountForAllUsers(allUsers: Boolean);
begin
  ckMountForAllUsers.Checked := allUsers;
end;

function TfrmKeyEntryLUKS.GetMountForAllUsers(): Boolean;
begin
  Result := ckMountForAllUsers.Checked;
end;


procedure TfrmKeyEntryLUKS.ckSelected(Sender: TObject);
begin
  EnableDisableControls();

end;


procedure TfrmKeyEntryLUKS.Initialize();
begin
  OTFEFreeOTFELUKSKeyOrKeyfileEntry1.FreeOTFEObj := fFreeOTFEObj;
  OTFEFreeOTFELUKSKeyOrKeyfileEntry1.Initialize();

  PopulateDrives();
  PopulateMountAs();

  DefaultOptions();
end;

end.
