unit uCommon;

interface

uses
  Winapi.Messages,
  System.SysUtils;

const
   PAGE_EXECUTE_READWRITE = $40;
   FILE_MAP_EXECUTE       = $20;
   FILE_MAP_RECV_MESSAGE  = WM_USER + $102;
   SHARE_MEMORY_SIZE      = 1024 * 1024 * 5; // 5M���ڴ��С��ȫ���˰ɣ�


type
  PShareMemRec = ^TShareMemRec;
  TShareMemRec = packed record
    hWd: Cardinal;
    // ��������
    FiterVer: Word;
    FiterIpAddress: Cardinal;
    FiterPort: Word;
    FiterUin: Cardinal;

    SAddr: Cardinal;
    SPort: Word;
    DAddr: Cardinal;
    DPort: Word;

    /// <summary>
    ///   Զ�̲���Ķ˿�, �ɵ���ע��dll����
    /// </summary>
    CapturePort: Word;

    /// <summary>
    ///   �ṩ��Զ�̵��ú����ĵ�ַ
    /// </summary>
    RemoteSendAddr: Pointer;
  end;

  // �ڰ��л�ȡ���������ù��˵�
  TRTXDataHeadRec = packed record
    Version: Word; // 3-2
    Cmd: Word;     // 5-2
    Uin: Cardinal; // 9-4
  end;

  TRTXDataRec = packed record
    DataSize: Integer;
    IsSend: Boolean;
    TestBytes: TBytes; // �۲�������

    SAddr: Cardinal;
    SPort: Word;
    DAddr: Cardinal;
    DPort: Word;
    STime: TDateTime;

    Head: Byte;
    Len: Word;
    Version: Word;
    Cmd: Word;
    Seq: Word;
    Uin: Cardinal;
    Data: TBytes;
    Tail: Byte;
  end;

//  TRTXRemoteCallParams = packed record
//    Len: Integer;
//    Data: Pointer;
//  end;

var
  gSharePtr: PShareMemRec = nil;


  function GetDataPtr: Pointer; inline;
implementation

function GetDataPtr: Pointer;
begin
  Result := Pointer(Cardinal(gSharePtr) + SizeOf(TShareMemRec) + 1);
end;

end.
