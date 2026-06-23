unit ActionBarHelper;

interface

uses debug_except, System.SysUtils, ExtendIntf, Vcl.ActnMan, VCL.ActnList, System.Classes, System.Actions, System.AnsiStrings;

type
 TActionBarHelper = class
 private
  class var FAction: TCustomAction;
  class var FCaption: string;
  class var FResult: TActionClientItem;
  class var FNeedFreeAction: Tarray<TActionClient>;
  class procedure IterateMenus(AClient: TActionClient);
  class procedure ByAction(AClient: TActionClient);
  class procedure ByCaption(AClient: TActionClient);
  class function FindByAction(ActionBar: TActionClient; Action: IAction): TActionClientItem;
  class function FindByCaption(ActionBar: TActionClient; Action: IAction): TActionClientItem; overload;
  class function FindByCaption(ActionBar: TActionClient; const Caption: string): TActionClientItem; overload;
 public
  class procedure ShowArr(ActionBar: TActionClient; const path: TArray<TMenuPath>; Action: IAction; ActionIndex: Integer = -1);
  class procedure Show(ActionBar: TActionClient; path: string; Action: IAction; Index: Integer = -1);
//  class procedure Show2(ActionBar: TActionClient; path: string; Action: TContainedAction; Index: Integer = -1);
  class procedure Index(ActionBar: TActionClient; capt: string; Index: Integer);
  class procedure Hide(ActionBar: TActionClient; Action: IAction);
  class function HideUnusedMenus(ActionMan: TActionManager): boolean;
  class procedure ShowHidenActions(ActionMan: TActionManager);
  class procedure VisibleContainedToIAction(ActionMan: TActionManager);
 end;

implementation

uses tools;

{ TActionBarHelper }

class procedure TActionBarHelper.ByAction(AClient: TActionClient);
begin
  if Assigned(FResult) then Exit;
  if AClient is TActionClientItem then
    with TActionClientItem(AClient) do
      if Action = FAction then
        FResult := TActionClientItem(AClient);
end;

class function TActionBarHelper.FindByAction(ActionBar: TActionClient; Action: IAction): TActionClientItem;
begin
  FResult := nil;
  FAction := TCustomAction((Action as IInterfaceComponentReference).GetComponent);
  ActionBar.Items.IterateClients(ActionBar.Items, ByAction);
  Result := FResult;
end;

class function TActionBarHelper.FindByCaption(ActionBar: TActionClient; const Caption: string): TActionClientItem;
begin
  FResult := nil;
  FCaption := Caption;
  ActionBar.Items.IterateClients(ActionBar.Items, ByCaption);
  Result := FResult;
end;

class procedure TActionBarHelper.ByCaption(AClient: TActionClient);
begin
  if AClient is TActionClientItem then
    with TActionClientItem(AClient) do
      if AnsiCompareText(AnsiReplaceStr(AnsiString(Caption), '&', ''), AnsiString(FCaption)) = 0 then
        FResult := TActionClientItem(AClient);
end;

class function TActionBarHelper.FindByCaption(ActionBar: TActionClient; Action: IAction): TActionClientItem;
begin
  FResult := nil;
  FCaption := TCustomAction((Action as IInterfaceComponentReference).GetComponent).Caption;
  ActionBar.Items.IterateClients(ActionBar.Items, ByCaption);
  Result := FResult;
end;

class procedure TActionBarHelper.Hide(ActionBar: TActionClient; Action: IAction);
 var
  a, b: TActionClientItem;
begin
  repeat
    b := FindByAction(ActionBar, Action);
    if Assigned(b) then
     repeat
      a := b;
      if Assigned(b.ParentItem) and (b.ParentItem is TActionClientItem) then b := TActionClientItem(b.ParentItem)
      else b := nil;
      a.Free;
     until not (Assigned(b) and not b.HasItems);
  until not Assigned(b);
end;

class procedure TActionBarHelper.IterateMenus(AClient: TActionClient);
begin
  if (AClient is TActionClientItem) and (TActionClientItem(AClient).Caption <> '-') and not Assigned(TActionClientItem(AClient).Action)
     and not AClient.HasItems then  CArray.Add<TActionClient>(FNeedFreeAction, AClient);
end;

class function TActionBarHelper.HideUnusedMenus(ActionMan: TActionManager): Boolean;
 var
  ac: TActionClient;
begin
  SetLength(FNeedFreeAction, 0);
  ActionMan.ActionBars.IterateClients(ActionMan.ActionBars, IterateMenus);
  Result := False;
  for ac in FNeedFreeAction do
   begin
    ac.Free;
    Result := True;
   end;
  SetLength(FNeedFreeAction, 0);
end;

class procedure TActionBarHelper.Index(ActionBar: TActionClient; capt: string; Index: Integer);
 var
  a: TActionClientItem;
begin
  a := FindByCaption(ActionBar, capt);
  if Assigned(a) and (a.OwningCollection.Count > Index) then a.Index := Index;
end;

class procedure TActionBarHelper.Show(ActionBar: TActionClient; path: string; Action: IAction; Index: Integer = -1);
 var
  a, root, rootA: TActionClientItem;
  s, sA: string;
begin
  rootA := nil;
  TActionClient(root) := ActionBar;
  for s in path.Split(['.'], TStringSplitOptions.ExcludeEmpty) do
   begin
    a := FindByCaption(root, s);
    if Assigned(a) then
     begin
      root := a;
      root.Visible := True;
     end
    else
     begin
      if root = ActionBar then
       begin
        root := root.Items.Add;
        sA := s;
        rootA := root;
       end
      else root := root.Items.Add;
      root.Caption := s;
      root.Visible := True;
     end;
   end;
  a := FindByCaption(root, Action.Caption);
  if Assigned(a) then
   begin
    a.Action := TCustomAction((Action as IInterfaceComponentReference).GetComponent);
    a.Action.Visible := True;
    a.Visible := True;
    Exit;
   end
  else if Assigned(FindByAction(root, Action)) then Exit;
  root := root.Items.Add;
  if FAction.Caption = '-' then root.Caption := '-'
  else root.Action := FAction;
  if (Index >= 0) and (Index < root.OwningCollection.Count) then root.Index := Index;
  if Assigned(rootA) then
  begin
   rootA.Action := FAction;
   rootA.ImageIndex := -1;
   rootA.Caption := sA;
  end;
end;

{class procedure TActionBarHelper.Show2(ActionBar: TActionClient; path: string; Action: TContainedAction; Index: Integer);
 var
  a, root: TActionClientItem;
  s: string;
begin
  TActionClient(root) := ActionBar;
  for s in path.Split(['.'], TStringSplitOptions.ExcludeEmpty) do
   begin
    a := FindByCaption(root, s);
    if Assigned(a) then root := a
    else
     begin
      root := root.Items.Add;
      root.Caption := s;
      root.Visible := True;
     end;
   end;
  root := root.Items.Add;
  root.Action := Action;
  if (Index >= 0) and (Index < root.OwningCollection.Count) then root.Index := Index;
end; }

class procedure TActionBarHelper.ShowArr(ActionBar: TActionClient; const path: TArray<TMenuPath>; Action: IAction;  ActionIndex: Integer);
 var
  a, root, rootA: TActionClientItem;
  pf, pfA: TMenuPath;
begin
  rootA := nil;
  TActionClient(root) := ActionBar;
  for pf in path do
   begin
    a := FindByCaption(root, pf.Caption);
    if Assigned(a) then
     begin
      root := a;
      if Assigned(root.Action) then root.Action.Visible := True;
      root.Visible := True;
     end
    else
     begin
      a := root.Items.Add;
      a.Caption := pf.Caption;
      a.Visible := True;
      if (pf.Index >= 0) and (pf.Index < a.OwningCollection.Count) then a.Index := pf.Index;
      if root = ActionBar then
       begin
        rootA := a;
        pfA := pf;
       end;
      root := a;
     end;
   end;
  a := FindByCaption(root, Action.Caption);
  if Assigned(a) then
   begin
    a.Action := TCustomAction((Action as IInterfaceComponentReference).GetComponent);
    a.Action.Visible := True;
    a.Visible := True;
   end
  else if not Assigned(FindByAction(root, Action)) then
   begin
    a := root.Items.Add;
    a.Action := FAction;
    if (ActionIndex >= 0) and (ActionIndex < a.OwningCollection.Count) then a.Index := ActionIndex;
    if Action.DividerBefore then
     begin
      if (a.Index > 0) and (root.Items[a.Index-1].Caption = '-') then Exit;
      root := root.Items.Add;
      root.Caption := '-';
      root.Index := a.Index;
     end;
    if Assigned(rootA) then
     begin
      rootA.Action := FAction;
      rootA.ImageIndex := -1;
      rootA.Caption := pfA.Caption;
     end;
   end;
end;

class procedure TActionBarHelper.ShowHidenActions(ActionMan: TActionManager);
 var
  a: TContainedAction;
  ia: IAction;
begin
  for a in ActionMan do if Supports(a, IAction, ia) then ia.DefaultShow;
end;

class procedure TActionBarHelper.VisibleContainedToIAction(ActionMan: TActionManager);
 var
  a: TContainedAction;
  ia: IAction;
begin
  for a in ActionMan do if Supports(a, IAction, ia) then
   begin
    ia.Visible := a.Visible;
   end;
end;

end.

