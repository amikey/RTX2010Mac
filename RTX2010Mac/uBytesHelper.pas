//***************************************************************************
//
//       ���ƣ�uBytesHelper.pas
//       ���ߣ�RAD Studio XE8
//       ���ڣ�2015/10/16 20:44:07
//       ���ߣ�ying32
//       QQ  ��1444386932
//       E-mail��yuanfen3287@vip.qq.com
//       ��Ȩ���� (C) 2015-2015 ying32.com All Rights Reserved
//
//
//***************************************************************************
unit uBytesHelper;

interface

uses
  System.SysUtils;

type
  TBytesHelper = record helper for TBytes
  private
    function GetLength: Integer;
    function GetHigh: Integer;
  public
    property Length: Integer read GetLength;
    property High: Integer read GetHigh;
  end;

implementation

{ TBytesHelper }

function TBytesHelper.GetHigh: Integer;
begin
  Result := High(Self);
end;

function TBytesHelper.GetLength: Integer;
begin
  Result := Length(Self);
end;

end.