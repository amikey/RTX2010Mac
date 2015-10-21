unit uMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.ExtCtrls,
  Vcl.StdCtrls, Winapi.TlHelp32, Winapi.ShellAPI, Vcl.Menus,
  System.Actions, Vcl.ActnList, System.Generics.Collections,
  QQTEA, CnHexEditor, Vcl.Clipbrd, uCommon;



type
  Tfrm_RTXPacket = class(TForm)
    pnl1: TPanel;
    pnl2: TPanel;
    stat1: TStatusBar;
    lv1: TListView;
    pnl3: TPanel;
    lbl1: TLabel;
    cbb_ProcessList: TComboBox;
    btn_refprocess: TButton;
    btn_Start: TButton;
    btn_Stop: TButton;
    btn_Clear: TButton;
    pm1: TPopupMenu;
    actlst1: TActionList;
    act_UseTouchKeyDecrypt: TAction;
    ouchKey2: TMenuItem;
    act_UseSessionKeyDecrypt: TAction;
    SessionKey1: TMenuItem;
    act_clearpackets: TAction;
    btn_GetAllKeys: TButton;
    lbl3: TLabel;
    lbl4: TLabel;
    lbl5: TLabel;
    edt_TouchKey: TEdit;
    edt_Passkey2: TEdit;
    edt_SessionKey: TEdit;
    lbl6: TLabel;
    act_UsePasskey2Decrypt: TAction;
    PassKey21: TMenuItem;
    lbl8: TLabel;
    lbl9: TLabel;
    edt_usr: TEdit;
    spl1: TSplitter;
    pm_HexEditor: TPopupMenu;
    act_hex_copysel: TAction;
    N1: TMenuItem;
    spl2: TSplitter;
    mmo1: TMemo;
    act_converttotext: TAction;
    lbl10: TLabel;
    edt_filter: TEdit;
    lbl11: TLabel;
    btnMakeCommetFile: TButton;
    act_MakeCommetFile: TAction;
    btnLoadBuffer: TButton;
    btnSaveBuffer: TButton;
    act_SaveBuffer: TAction;
    act_LoadBuffer: TAction;
    dlgOpen1: TOpenDialog;
    procedure FormCreate(Sender: TObject);
    procedure btn_refprocessClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btn_StartClick(Sender: TObject);
    procedure btn_StopClick(Sender: TObject);
    procedure act_clearpacketsUpdate(Sender: TObject);
    procedure act_clearpacketsExecute(Sender: TObject);
    procedure btn_GetAllKeysClick(Sender: TObject);
    procedure act_UseSessionKeyDecryptExecute(Sender: TObject);
    procedure lv1AdvancedCustomDrawItem(Sender: TCustomListView;
      Item: TListItem; State: TCustomDrawState; Stage: TCustomDrawStage;
      var DefaultDraw: Boolean);
    procedure lv1DblClick(Sender: TObject);
    procedure act_hex_copyselExecute(Sender: TObject);
    procedure act_converttotextExecute(Sender: TObject);
    procedure act_MakeCommetFileUpdate(Sender: TObject);
    procedure act_MakeCommetFileExecute(Sender: TObject);
    procedure act_SaveBufferExecute(Sender: TObject);
    procedure act_LoadBufferExecute(Sender: TObject);
  private
    FHandle: THandle;
    FPid: THandle;

    FPackets: TList<TRTXDataRec>;
    FTouchKey: TBytes;
    FPassKey2: TBytes;
    FNameKey: TBytes;
    FSessionKey: TBytes;

    FHexEditor: TCnHexEditor;
    procedure ParseFilterStr;
    procedure RefProcessList;
    procedure ProcessRecv(var Msg: TMessage); message FILE_MAP_RECV_MESSAGE;
    procedure InjectDll;
    procedure UnjectDll;
    procedure MakeCommentFile;
    procedure AddToListView(AItem: TRTXDataRec);
  public
    { Public declarations }
  end;

var
  frm_RTXPacket: Tfrm_RTXPacket;

implementation

{$R *.dfm}

uses Winapi.Winsock2, uRTXPacketRWriter, uBytesHelper, CnMD5, System.Math,
  uBufferFile;


function BytesToString(const ABytes: TBytes): string;
var
  B: Byte;
begin
  Result := '';
  for B in ABytes do
    Result := Result + B.ToHexString(2) + ' ';
  Result := Result.Trim;
end;

function Passkey2(APassword: string): TBytes;
{$IF Defined(MSWINDOWS) and not Defined(DelphiXE8)}
var
  pp, dd: TBytes;
  M: TMD5Digest;
begin
  pp := BytesOf(APassword);
  SetLength(dd, $10);
  Move(pp[0], dd[0], Min(Length(pp), $10));
  SetLength(Result, $10);
  M := MD5Buffer(dd, Length(dd));
  Move(M, Result[0], SizeOf(TMD5Digest));
end;
{$ELSE}
var
  pp, dd: TBytes;
  M: THashMD5;
begin
  pp := BytesOf(APassword);
  SetLength(dd, $10);
  Move(pp[0], dd[0], Min(Length(pp), $10));
  SetLength(Result, $10);
  M := THashMD5.Create;
  M.Update(dd);
  Move(M.HashAsBytes[0], Result[0], $10);
end;
{$ENDIF}

function NameKey3(AName: string): TBytes;
{$IF Defined(MSWINDOWS) and not Defined(DelphiXE8)}
var
  M: TMD5Digest;
  LBytes: TBytes;
begin
  SetLength(Result, $10);
  LBytes := TEncoding.Unicode.GetBytes(AName);
  M := MD5Buffer(LBytes, Length(LBytes));
  Move(M, Result[0], SizeOf(TMD5Digest));
end;
{$ELSE}
var
  M: THashMD5;
  LBytes: TBytes;
begin
  SetLength(Result, $10);
  LBytes := TEncoding.Unicode.GetBytes(AName);
  M := THashMD5.Create;
  M.Update(LBytes);
  Move(M.HashAsBytes[0], Result[0], $10);
end;
{$ENDIF}

{ TForm1 }

procedure Tfrm_RTXPacket.act_clearpacketsExecute(Sender: TObject);
begin
  FPackets.Clear;
  lv1.Clear;
end;

procedure Tfrm_RTXPacket.act_clearpacketsUpdate(Sender: TObject);
begin
  TAction(Sender).Enabled := Assigned(FPackets) and (FPackets.Count > 0);
end;

procedure Tfrm_RTXPacket.act_converttotextExecute(Sender: TObject);
var
  LBytes: TBytes;
begin
  if FHexEditor.SelLength = 0 then Exit;
  SetLength(LBytes, FHexEditor.SelLength);
  FHexEditor.MemoryStream.Position := FHexEditor.SelStart;
  FHexEditor.MemoryStream.Read(LBytes, 0, LBytes.Length);
  try
    mmo1.Text := TEncoding.Unicode.GetString(LBytes);
  except
    on E: Exception do
      mmo1.Text := '����' + E.Message;
  end;
end;

procedure Tfrm_RTXPacket.act_hex_copyselExecute(Sender: TObject);
begin
  Clipboard.AsText := FHexEditor.SelText;
end;

procedure Tfrm_RTXPacket.act_LoadBufferExecute(Sender: TObject);
var
  LFile: TBufferFile;
  LItem: TRTXDataRec;
begin
  if dlgOpen1.Execute then
  begin
    LFile := TBufferFile.Create(FPackets);
    try
      LFile.LoadFromFile(dlgOpen1.FileName);
      for LItem in FPackets do
        AddToListView(LItem);
      SetLength(FSessionKey, $10);
      FSessionKey := LFile.SessionKey;
      edt_SessionKey.Text := BytesToString(FSessionKey);
    finally
      LFile.Free;
    end;
  end;
end;

procedure Tfrm_RTXPacket.act_MakeCommetFileExecute(Sender: TObject);
begin
  MakeCommentFile;
end;

procedure Tfrm_RTXPacket.act_MakeCommetFileUpdate(Sender: TObject);
begin
  TAction(Sender).Enabled := FPackets.Count > 0;
end;

procedure Tfrm_RTXPacket.act_SaveBufferExecute(Sender: TObject);
var
  LFile: TBufferFile;
begin
  LFile := TBufferFile.Create(FPackets);
  try
    LFile.SessionKey := FSessionKey;
    LFile.SaveToFile(Format('%s%s.rtxbuf', [ExtractFilePath(ParamStr(0))
     ,FormatDateTime('YYYYMMMDDhhmmss', Now)]));
  finally
    LFile.Free;
  end;
end;

procedure Tfrm_RTXPacket.act_UseSessionKeyDecryptExecute(Sender: TObject);
var
  LDeData: TBytes;
  I: Integer;
  LRawData: TBytes;
begin
  I := lv1.ItemIndex;
  if (I <> -1) and (FSessionKey <> nil) and (FSessionKey.Length = $10) then
  begin
    stat1.Panels.Items[0].Text := '';
    LDeData := QQTEADeCrypt(FPackets[I].Data, FSessionKey);
    if LDeData <> nil then
      FHexEditor.LoadFromBuffer(LDeData[0], LDeData.Length)
    else
    begin
      SetLength(LRawData, FPackets[I].Len - $E - 1);
      Move(FPackets[I].Data[1], LRawData[0], LRawData.Length);
      LDeData := QQTEADeCrypt(LRawData, FPassKey2);
      if LDeData <> nil then
        FHexEditor.LoadFromBuffer(LDeData[0], LDeData.Length)
      else
        stat1.Panels.Items[0].Text := 'SessionKey����ʧ�ܣ�';
    end;
  end;
end;

procedure Tfrm_RTXPacket.AddToListView(AItem: TRTXDataRec);
var
  LItem: TListItem;
begin
  LItem := lv1.Items.Add;
  LItem.Caption := lv1.Items.Count.ToString;
  LItem.SubItems.Add(FormatDateTime('hh:mm:ss:zzz', Now));
  if AItem.IsSend then
    LItem.SubItems.Add('send')
  else Litem.SubItems.Add('recv');
  LItem.SubItems.Add(string(inet_ntoa(TInAddr(AItem.SAddr))));
  LItem.SubItems.Add(AItem.SPort.ToString);
  LItem.SubItems.Add(string(inet_ntoa(TInAddr(AItem.DAddr))));
  LItem.SubItems.Add(AItem.DPort.ToString);
  LItem.SubItems.Add(Format('%d(%.4x)', [AItem.Len, Integer(AItem.Len)]));
  LItem.SubItems.Add(AItem.Version.ToHexString(4));
  LItem.SubItems.Add(AItem.Cmd.ToHexString(4));
  LItem.SubItems.Add(AItem.Seq.ToHexString(4));
  LItem.SubItems.Add(AItem.Uin.ToString);

end;

procedure Tfrm_RTXPacket.btn_GetAllKeysClick(Sender: TObject);
var
  LData: TRTXDataRec;
  LRawData: TBytes;
  LTEADeData: TBytes;
begin
  for LData in FPackets do
  begin
    if (LData.Cmd = $400) and LData.IsSend  then
    begin
      if LData.Data.Length > $10 then
      begin
        SetLength(FTouchKey, $10);
        Move(LData.Data[0], FTouchKey[0], FTouchKey.Length);
        edt_TouchKey.Text := BytesToString(FTouchKey);
      end;
    end else if (LData.Cmd = $401) and (not LData.IsSend) then
    begin
      SetLength(LRawData, LData.Len - $E - 1);
      Move(LData.Data[1], LRawData[0], LRawData.Length);

      LTEADeData := QQTEADeCrypt(LRawData, FPassKey2);
      if LTEADeData <> nil then
      begin
        SetLength(FSessionKey, $10);
        Move(LTEADeData[4], FSessionKey[0], $10);
        edt_SessionKey.Text := BytesToString(FSessionKey);
      end else
      begin
        OutputDebugString('PassKey2 decrypt faild.');
        LTEADeData := QQTEADeCrypt(LRawData, FNameKey);
        if LTEADeData <> nil then
        begin
          SetLength(FSessionKey, $10);
          Move(LTEADeData[4], FSessionKey[0], $10);
          edt_SessionKey.Text := BytesToString(FSessionKey);
        end else OutputDebugString('NameKey decrypt faild.');
      end;
    end;
  end;
end;

procedure Tfrm_RTXPacket.btn_refprocessClick(Sender: TObject);
begin
  RefProcessList;
end;

procedure Tfrm_RTXPacket.btn_StartClick(Sender: TObject);
begin
  if gSharePtr <> nil then
  begin
    ParseFilterStr;
    gSharePtr^.hWd := Self.Handle;
    FPassKey2 := Passkey2(edt_Passkey2.Text);
    FNameKey :=  NameKey3(edt_usr.Text);
  end;
  InjectDll;
end;

procedure Tfrm_RTXPacket.btn_StopClick(Sender: TObject);
begin
  UnjectDll;
end;

procedure Tfrm_RTXPacket.FormCreate(Sender: TObject);
begin
  FHexEditor := TCnHexEditor.Create(Self);
  FHexEditor.Parent := pnl3;
  FHexEditor.Align := alClient;
  FHexEditor.PopupMenu := pm_HexEditor;
  RefProcessList;
  FPackets := TList<TRTXDataRec>.Create;
  btn_Stop.Enabled := False;
  FHandle := CreateFileMapping(INVALID_HANDLE_VALUE, nil, PAGE_EXECUTE_READWRITE, 0, SHARE_MEMORY_SIZE, 'global/rtxpacket/');
  if FHandle > 0 then
    gSharePtr := MapViewOfFile(FHandle, FILE_MAP_EXECUTE or FILE_MAP_READ or FILE_MAP_WRITE, 0, 0, 0);
end;

procedure Tfrm_RTXPacket.FormDestroy(Sender: TObject);
begin
  UnjectDll;
  if gSharePtr <> nil then
    UnmapViewOfFile(gSharePtr);
  if FHandle <> 0 then
    Closehandle(FHandle);
  FPackets.Free;
end;

procedure Tfrm_RTXPacket.InjectDll;
var
  hProcess, RemoteThreadHandle: THandle;
  pFileNameRemote, pfnAddr: Pointer;
  lpNumberOfBytesWritten: SIZE_T;
  lpThreadId: DWORD;
begin
  FPid := 0;
  if cbb_ProcessList.ItemIndex <> -1 then
  begin
    FPid := THandle(cbb_ProcessList.Items.Objects[cbb_ProcessList.ItemIndex]);
    if FPid <> 0 then
    begin
      hProcess := OpenProcess(PROCESS_ALL_ACCESS, False, FPid);
      if hProcess > 0 then
      begin
        pFileNameRemote := VirtualAllocEx(hProcess, nil, 4096 * 4, MEM_COMMIT or MEM_RESERVE, PAGE_EXECUTE_READWRITE);
        if WriteProcessMemory(hProcess, pFileNameRemote,
          PChar(ExtractFilePath(ParamStr(0)) + 'RTXPacketHook.dll')
        , 4096 * 4, lpNumberOfBytesWritten) then
        begin
          pfnAddr := GetProcAddress(GetModuleHandle(Kernel32), 'LoadLibraryW');
          if pfnAddr <> nil then
          begin
            RemoteThreadHandle := CreateRemoteThread(hProcess, nil, 0, pfnAddr, pFileNameRemote, 0, lpThreadId);
            if RemoteThreadHandle <> 0 then
            begin
              WaitForSingleObject(RemoteThreadHandle, INFINITE);
              btn_Stop.Enabled := True;
              btn_Start.Enabled := False;
              CloseHandle(RemoteThreadHandle);
            end;
          end;
        end;
        if pFileNameRemote <> nil then
          VirtualFreeEx(hProcess, pFileNameRemote, 0, MEM_RELEASE);
        CloseHandle(hProcess);
      end;
    end;
  end;
end;

procedure Tfrm_RTXPacket.lv1AdvancedCustomDrawItem(Sender: TCustomListView;
  Item: TListItem; State: TCustomDrawState; Stage: TCustomDrawStage;
  var DefaultDraw: Boolean);
begin
  if SameText(Item.SubItems[1], 'send') then
    Sender.Canvas.Font.Color := clGreen
  else Sender.Canvas.Font.Color := clRed;
end;

procedure Tfrm_RTXPacket.lv1DblClick(Sender: TObject);
begin
  if lv1.ItemIndex <> -1 then
    FHexEditor.LoadFromBuffer(FPackets[lv1.ItemIndex].TestBytes[0], FPackets[lv1.ItemIndex].TestBytes.Length);
end;


{
      $0400 :
        begin
          if LItem.IsSend then
          begin

          end else
          begin

          end;
        end;
}
procedure Tfrm_RTXPacket.MakeCommentFile;
var
  LRTXData: TRTXStream;
  LItem: TRTXDataRec;
  LTouchKey: TBytes;
  LFile: TFileStream;
  LInt: Integer;
  LTempBytes, LTempBytes2, LSalt: TBytes;
  LAuthType: Integer;

  function ifstr(b: Boolean; atrue, afalse: string): string;
  begin
    if b then Result := atrue else Result := afalse;
  end;

  procedure WStr(const s: string); overload;
  var
    LB: TBytes;
  begin
    LB := BytesOf(s+#13#10);
    LFile.Write(LB, 0, LB.Length);
  end;

  procedure WStr(const s, acomment: string); overload;
  begin
    WStr(s + '     // ' + acomment);
  end;

  procedure WSp;
  begin
    WStr('-------------------------------------------------');
  end;

  procedure WInt(AInt: Integer; acomment: string);
  begin
    WStr(AInt.ToHexString(4), acomment);
  end;

  procedure WCmdStr(c: Word; isSend:Boolean; acomment: string);
  begin
    WStr('CMD=' + c.ToHexString(4) + '   ' + ifstr(issend, 'send', 'recv'), acomment);
  end;

  procedure WBytesStr(adata: TBytes; const acomment: string);
  begin
    WStr(BytesToString(adata), acomment);
  end;

begin
  LAuthType := 0;
  LSalt := nil;
  LFile := TFileStream.Create(ExtractFilePath(ParamStr(0)) + 'rtxcomment.txt', fmCreate);
  try
    LRTXData := TRTXStream.Create(True);
    try
      for LItem in FPackets do
      begin

        case LItem.Cmd of
          $0400 :
            begin
              if LItem.IsSend then
              begin
                LRTXData.LoadBytes(LItem.Data);
                SetLength(LTouchKey, $10);
                LTouchKey := LRTXData.ReadBytes($10);
                WCmdStr(LItem.Cmd, LItem.IsSend,'��¼�ĵ�һ����');
                WBytesStr(LTouchKey, 'TouchKey');
                LInt := LRTXData.ReadByte;
                WInt(LInt, '�������ݵĳ���');
                LTempBytes := LRTXData.ReadBytes(LInt);
                WBytesStr(LTempBytes, 'TEA��������');
                WStr('-------TEA���ݽ��ܿ�ʼ');
                  LTempBytes := QQTEADeCrypt(LTempBytes, LTouchKey);
                  if LTempBytes <> nil then
                  begin
                    WBytesStr(LTempBytes, 'TEA��������');
                    // �����ֳ���
                    LInt := 0;
                    Move(LtempBytes[1], LInt, 1);
                    WInt(LInt, '���Ƴ���');
                    SetLength(LTempBytes2, LInt - 1);
                    Move(LtempBytes[2], LTempBytes2[0], LTempBytes2.Length);
                    WStr(TEncoding.Unicode.GetString(LTempBytes2), '��¼�ʺ�');
                  end;
                WStr('-------TEA���ݽ������');
                WSp;
              end else
              begin
                LRTXData.LoadBytes(QQTEADeCrypt(LItem.Data, LTouchKey));
                WCmdStr(LItem.Cmd, LItem.IsSend,'��¼�ĵ�2����');

                WInt(LRTXData.ReadByte, '��¼״̬��$FE��ʾ�û������ڣ�$02, $00��ʾ����');
                WInt(LRTXData.ReadCardinal, '�û���UIN');
                WStr(LRTXData.ReadUnicode, '�û���¼�ʺ�����');
                LSalt := LRTXData.ReadBytes(4);
                WBytesStr(LSalt, '���ڼ��ܵ�һ������, �����õ��ŵ�');
                LAuthType := LRTXData.ReadByte; // �����õ���
                WInt(LAuthType, '��֤���ͣ�0 passkey1, passkey2,  1 namekey');
                WSp;
                // ���滹��Ҫɶ��
              end;
            end;

          $0401 :
            begin
              LRTXData.LoadBytes(LItem.Data);
              if LItem.IsSend then
              begin
                if LAuthType = 0 then
                begin
                  WInt(LAuthType, '��֤��ʽ=0');
                  WStr(LRTXData.ReadUnicode, '�ʺ���');
                  WInt(LRTXData.ReadByte, '1');
                  LInt := LRTXData.ReadByte;
                  WInt(LInt, 'Token1����');
                  WBytesStr(LRTXData.ReadBytes(LInt), 'Token1,��LSalt+Passkey1���ܵ�����');
                  LInt := LRTXData.ReadByte;
                  WInt(LInt, 'Token2����');
                  WBytesStr(LRTXData.ReadBytes(LInt), 'Token2,��LSalt+Passkey2���ܵ�����');
                  WBytesStr(LRTXData.ReadBytes($10), '���16�ֽ�');
                  WInt(LRTXData.ReadByte, '0');
                end else
                begin
                  WInt(LAuthType, '��֤��ʽ=' + LAuthType.ToString);
                  LInt := LRTXData.ReadByte;
                  WInt(LInt, '�������볤��');
                  WStr(StringOf(LRTXData.ReadBytes(LInt)), '��������');
                  WBytesStr(LSalt, 'Salt');
                  LInt := LRTXData.ReadByte;
                  WInt(LInt, 'Token����');
                  WBytesStr(LRTXData.ReadBytes(LInt), 'Token����NameKey���ܵ�����');
                  WInt(LRTXData.ReadByte, '0');
                  WBytesStr(LRTXData.ReadBytes($10), '���16�ֽ�key');
                  WInt(LRTXData.ReadByte, '0');

                end;
              end else
              begin

              end;
            end;


        end;
      end;
    finally
      LRTXData.Free;
    end;
  finally
    LFile.Free;
  end;
end;

procedure Tfrm_RTXPacket.ParseFilterStr;
var
  LStrs: TStringList;
begin
  LStrs := TStringList.Create;
  try
    ExtractStrings([' '], [], PChar(Trim(edt_filter.Text)), LStrs);
    LStrs.NameValueSeparator := ':';
    gSharePtr^.FiterIpAddress := inet_addr(PAnsiChar(AnsiString(LStrs.Values['i'])));
    gSharePtr^.FiterPort := StrToIntDef(LStrs.Values['p'], 0);
    gSharePtr^.FiterUin := StrToIntDef(LStrs.Values['u'], 0);
    gSharePtr^.FiterVer := StrToIntDef(LStrs.Values['v'], 0);
    OutputDebugString(PChar(Format('Ip=%.8x, Port=%d, Uin=%d, Ver=%.4x',
     [
       gSharePtr^.FiterIpAddress,
       gSharePtr^.FiterPort,
       gSharePtr^.FiterUin,
       gSharePtr^.FiterVer
     ])));
  finally
    LStrs.Free;
  end;
end;

procedure Tfrm_RTXPacket.ProcessRecv(var Msg: TMessage);
var
  LHead: TRTXDataRec;
  LData: TRTXStream;
  LDataLen: Integer;
begin
//  OutputDebugString(PChar(Format('�յ���: ����=%d, ����=%d', [Msg.WParam, Msg.LParam])));
  if gSharePtr <> nil then
  begin
    LData := TRTXStream.Create(GetDataPtr, Msg.WParam, True);
    try
      LHead.DataSize := Msg.WParam;
      LHead.IsSend := Msg.LParam = 1;
      LHead.Head := LData.ReadByte;
      LHead.Len := LData.ReadWord;
      LHead.Version := LData.ReadWord;
      LHead.Cmd := LData.ReadWord;
      LHead.Seq := LData.ReadWord;
      LHead.Uin := LData.ReadCardinal;
      LDataLen := LHead.Len - $E;
      if LDataLen > 0 then
         LHead.Data := LData.ReadBytes(LDataLen);
      LHead.Tail := LData.ReadByte;

      SetLength(LHead.TestBytes, Msg.WParam);
      Move(GetDataPtr^, LHead.TestBytes[0], Msg.WParam);

      LHead.SAddr := gSharePtr^.SAddr;
      LHead.SPort := gSharePtr^.SPort;
      LHead.DAddr := gSharePtr^.DAddr;
      LHead.DPort := gSharePtr^.DPort;
      LHead.STime := Now;
      FPackets.Add(LHead);
      AddToListView(LHead);
    finally
      LData.Free;
    end;
  end;
end;

procedure Tfrm_RTXPacket.RefProcessList;
const
  PROCESS_TERMINATE = $0001;
var
  ContinueLoop: BOOL;
  FSnapShotHandle: THandle;
  FProcessEntry32: TProcessEntry32;
  Tmp: Integer;
begin
  Tmp := -1;
  FSnapShotHandle := CreateToolhelp32SnapShot(TH32CS_SNAPPROCESS, 0);
  FProcessEntry32.dwSize := SizeOf(FProcessEntry32);
  ContinueLoop := Process32First(FSnapShotHandle, FProcessEntry32);
  cbb_ProcessList.Items.BeginUpdate;
  while ContinueLoop do
  begin
    cbb_ProcessList.AddItem(Format('%.4x - %s',
       [FProcessEntry32.th32ProcessID, ExtractFileName(FProcessEntry32.szExeFile)]),
       TObject(FProcessEntry32.th32ProcessID));
    if Tmp = -1 then
    begin
      if SameText(ExtractFileName(FProcessEntry32.szExeFile), 'RTX.exe') then
        Tmp := cbb_ProcessList.Items.Count - 1;
    end;
    ContinueLoop := Process32Next(FSnapShotHandle, FProcessEntry32);
  end;
  if Tmp <> -1 then cbb_ProcessList.ItemIndex := Tmp;
  cbb_ProcessList.Items.EndUpdate;
  CloseHandle(FSnapShotHandle);
end;



procedure Tfrm_RTXPacket.UnjectDll;
var
  hProcess: THandle;
  pFileNameRemote, pfnAddr: Pointer;
  lpNumberOfBytesWritten: SIZE_T;
  lpThreadId: DWORD;
  RemoteThreadHandle: THandle;
  LResult: Cardinal;
begin
  if FPid <> 0 then
  begin
    hProcess := OpenProcess(PROCESS_ALL_ACCESS, False, FPid);
    if hProcess > 0 then
    begin
      LResult := 0;
      pFileNameRemote := VirtualAllocEx(hProcess, nil, 1024*4, MEM_COMMIT or MEM_RESERVE, PAGE_EXECUTE_READWRITE);
      if WriteProcessMemory(hProcess, pFileNameRemote, PChar(ExtractFilePath(ParamStr(0)) + 'RTXPacketHook.dll'), 1024*4, lpNumberOfBytesWritten) then
      begin
        pfnAddr := GetProcAddress(GetModuleHandle(Kernel32), 'GetModuleHandleW');
        if pfnAddr <> nil then
        begin
          RemoteThreadHandle := CreateRemoteThread(hProcess, nil, 0, pfnAddr, pFileNameRemote, 0, lpThreadId);
          if RemoteThreadHandle <> 0 then
          begin
            WaitForSingleObject(RemoteThreadHandle, INFINITE);
            GetExitCodeThread(RemoteThreadHandle, LResult)
          end;
          CloseHandle(RemoteThreadHandle);
        end;
      end;
      if pFileNameRemote <> nil then
        VirtualFreeEx(hProcess, pFileNameRemote, 0, MEM_RELEASE);
      if LResult <> 0 then
      begin
        pfnAddr := GetProcAddress(GetModuleHandle(kernel32), 'FreeLibrary');
        if pfnAddr <> nil then
        begin
          RemoteThreadHandle := CreateRemoteThread(hProcess, nil, 0, pfnAddr, Pointer(LResult), 0, lpThreadId);
          CloseHandle(RemoteThreadHandle);
        end;
      end;
      CloseHandle(hProcess);
    end;
  end;
  btn_Stop.Enabled := False;
  btn_Start.Enabled := True;
end;

end.