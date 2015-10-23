//***************************************************************************
//
//       名称：uMain.pas
//       工具：RAD Studio XE8
//       日期：2015/10/16 20:43:53
//       作者：ying32
//       QQ  ：1444386932
//       E-mail：yuanfen3287@vip.qq.com
//       版权所有 (C) 2015-2015 ying32.com All Rights Reserved
//
//
//***************************************************************************
unit uMain;

{$I 'RTX.inc'}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.TreeView, FMX.Layouts, FMX.Edit, FMX.Objects, FMX.Effects,
  FMX.Controls.Presentation, FMX.Menus, System.Actions, FMX.ActnList,
  FMX.ScrollBox, FMX.Memo, FMX.TabControl, FMX.ExtCtrls, FMX.ListView.Types,
  FMX.ListView, uSessionFrame, System.ImageList, FMX.ImgList, FMX.Notification,
  System.Hash;

type
  Tfrm_Main = class(TForm)
    mm_Main: TMainMenu;
    MenuItem1: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem8: TMenuItem;
    MenuItem9: TMenuItem;
    MenuItem10: TMenuItem;
    MenuItem3: TMenuItem;
    actlst1: TActionList;
    act_About: TAction;
    act_ExitApp: TAction;
    act_Setting: TAction;
    lyt_Session: TLayout;
    lyt_MessageView: TLayout;
    tbc1: TTabControl;
    lyt1: TLayout;
    TabItem1: TTabItem;
    TabItem2: TTabItem;
    edt1: TEdit;
    SearchEditButton1: TSearchEditButton;
    lyt2: TLayout;
    lyt4: TLayout;
    img1: TImage;
    txt_UserName: TText;
    lv1: TListView;
    tv1: TTreeView;
    trvwtm1: TTreeViewItem;
    trvwtm2: TTreeViewItem;
    trvwtm3: TTreeViewItem;
    stylbk1: TStyleBook;
    Line1: TLine;
    pm_Status: TPopupMenu;
    act_Status_Online: TAction;
    act_Status_Away: TAction;
    act_Status_Offline: TAction;
    il_Status: TImageList;
    MenuItem2: TMenuItem;
    MenuItem5: TMenuItem;
    MenuItem6: TMenuItem;
    btn_ChangeStatus: TSpeedButton;
    NotificationCenter: TNotificationCenter;
    btn1: TButton;
    procedure act_ExitAppExecute(Sender: TObject);
    procedure act_AboutExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure act_SettingExecute(Sender: TObject);
    procedure act_Status_OnlineExecute(Sender: TObject);
    procedure act_Status_OfflineExecute(Sender: TObject);
    procedure act_Status_AwayExecute(Sender: TObject);
    procedure btn_ChangeStatusClick(Sender: TObject);
    procedure btn1Click(Sender: TObject);
    procedure NotificationCenterReceiveLocalNotification(Sender: TObject;
      ANotification: TNotification);
  private
    FTestView: Tfra_Session;
  private
    procedure OnRTXIMMessage(Sender: TObject; const AFrom, ATo, ABody: string);
    procedure OnRTXLoginResult(Sender: TObject; AStatus: Integer);

    procedure TestListView;

    /// <summary>
    ///   设置Dock显示消息条数值
    /// </summary>
    procedure SetBadgeNumber(Value: Integer = 0);
    /// <summary>
    ///   发送通知
    /// </summary>
    procedure SendNotification(const ATitle, AText: string);
  public
    { Public declarations }
  end;

var
  frm_Main: Tfrm_Main;

implementation

{$R *.fmx}
{$R *.Macintosh.fmx MACOS}

uses uRTXNetModule, ufrmAbout, uDebug, ufrmSetting, uGlobalDef;

/// <summary>
///   发送通知用的
/// </summary>
function GetTimeMD5String: string;
begin
  Result := THashMD5.GetHashString(DateTimeToStr(Now));
end;

procedure Tfrm_Main.act_AboutExecute(Sender: TObject);
begin
  frm_About.ShowModal;
end;

procedure Tfrm_Main.act_ExitAppExecute(Sender: TObject);
begin
  Application.Terminate;
end;

procedure Tfrm_Main.act_SettingExecute(Sender: TObject);
begin
  frm_Setting.Show;
end;

procedure Tfrm_Main.act_Status_AwayExecute(Sender: TObject);
begin
//
end;

procedure Tfrm_Main.act_Status_OfflineExecute(Sender: TObject);
begin
//
end;

procedure Tfrm_Main.act_Status_OnlineExecute(Sender: TObject);
begin
//
end;

procedure Tfrm_Main.btn1Click(Sender: TObject);
begin
  SendNotification('测试', '测试通知');
end;

procedure Tfrm_Main.btn_ChangeStatusClick(Sender: TObject);
var
  P: TPointF;
begin
  P := ClientToScreen(btn_ChangeStatus.AbsoluteRect.Location);
  pm_Status.Popup(P.X, P.Y + btn_ChangeStatus.Height);
end;

procedure Tfrm_Main.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  DBG('Tfrm_Main.FormClose');
end;

procedure Tfrm_Main.FormCreate(Sender: TObject);
begin
  TestListView;
  DBG('Tfrm_Main.FormCreate');
  if Assigned(dm_RTXNetModule) then
  begin
    dm_RTXNetModule.RTXOnMainFormIMMessage := OnRTXIMMessage;
    dm_RTXNetModule.RTXOnMainFormLoginResult := OnRTXLoginResult;
  end;
  FTestView := CreateSessionFrame(Self, lyt_MessageView);
end;

procedure Tfrm_Main.NotificationCenterReceiveLocalNotification(Sender: TObject;
  ANotification: TNotification);
begin
  DBG('收到通知, Name=%s, Title=%s, AlertBody=%s, AlertAction=%s, Number=%d',
   [
     ANotification.Name,
     ANotification.Title,
     ANotification.AlertBody,
     ANotification.AlertAction,
     ANotification.Number
   ]);
  NotificationCenter.CancelNotification(ANotification.Name);
end;

procedure Tfrm_Main.OnRTXIMMessage(Sender: TObject; const AFrom, ATo,
  ABody: string);
begin

end;

procedure Tfrm_Main.OnRTXLoginResult(Sender: TObject; AStatus: Integer);
begin

end;

procedure Tfrm_Main.SendNotification(const ATitle, AText: string);
var
  N: TNotification;
begin
  if NotificationCenter.Supported then
  begin
    N := NotificationCenter.CreateNotification;
    try
      N.Name := 'RTX2010Notification_' + GetTimeMD5String;
      N.Title := ATitle;
      N.AlertBody := AText;
      N.FireDate := Now;
      NotificationCenter.PresentNotification(N);
    finally
      N.DisposeOf;
    end;
  end;
end;

procedure Tfrm_Main.SetBadgeNumber(Value: Integer);
begin
  if NotificationCenter.Supported then
  begin
    NotificationCenter.ApplicationIconBadgeNumber := Value;
    //if Value > 0 then
    //  NotificationCenter.ApplicationIconBadgeNumber := NotificationCenter.ApplicationIconBadgeNumber + Value
    //else if Value = 0 then
    //  NotificationCenter.ApplicationIconBadgeNumber := 0;
  end;
end;

procedure Tfrm_Main.TestListView;
var
  LItem: TListViewItem;
begin

  LItem := lv1.Items.Add;
  LItem.Text := '测试1';

  LItem := lv1.Items.Add;
  LItem.Text := '测试2';
end;

initialization
{$IFDEF MSWINDOWS}
//  GlobalUseDX10 := False;
{$ENDIF}

end.
