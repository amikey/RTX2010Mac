//***************************************************************************
//
//       ���ƣ�uRTXMessageView.pas
//       ���ߣ�RAD Studio XE8
//       ���ڣ�2015/10/18 12:45:53
//       ���ߣ�ying32
//       QQ  ��1444386932
//       E-mail��yuanfen3287@vip.qq.com
//       ��Ȩ���� (C) 2015-2015 ying32.com All Rights Reserved
//
//
//***************************************************************************
unit uRTXMessageView;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.TreeView, FMX.Layouts, FMX.Edit, FMX.Objects;

type
  TRTXMessageItem = class(TControl)
  private

  end;

  TRTXMessageItems = class(TPersistent)
  private

  end;


  TRTXMessageView = class(TVertScrollBox)
  private
    constructor Create(AOwner: TComponent); override;
  end;

implementation




{ TRTXMessageView }

constructor TRTXMessageView.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

end;

end.
