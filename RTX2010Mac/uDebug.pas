//***************************************************************************
//
//       ���ƣ�uDebug.pas
//       ���ߣ�RAD Studio XE8
//       ���ڣ�2015/10/16 20:44:27
//       ���ߣ�ying32
//       QQ  ��1444386932
//       E-mail��yuanfen3287@vip.qq.com
//       ��Ȩ���� (C) 2015-2015 ying32.com All Rights Reserved
//
//
//***************************************************************************
unit uDebug;

interface

uses
{$IFDEF MSWINDOWS}
  Winapi.Windows,
{$ENDIF}
{$IFDEF MACOS}
  FMX.Types,
{$ENDIF}
  System.SysUtils;

procedure DBG(const s: string; args: array of const); overload;
procedure DBG(const s: string); overload;
procedure PrintBytes(ABytes: TBytes; AText: string = '');

implementation

procedure DBG(const s: string; args: array of const); overload;
begin
{$IFDEF MSWINDOWS}
  OutputDebugString(PChar(Format(s, args)));
{$ELSE}
  Log.d(s, args);
{$ENDIF}
end;

procedure DBG(const s: string); overload;
begin
  DBG(s, []);
end;

procedure PrintBytes(ABytes: TBytes; AText: string = '');
var
  B: Byte;
  S: string;
begin
  S := '';
  for B in ABytes do
    S := S + B.ToHexString(2) + ' ';
{$IFDEF MSWINDOWS}
  OutputDebugString(PChar(AText + '=' + S));
{$ELSE}
  Log.d(AText + '=' + S);
{$ENDIF}
end;

end.
