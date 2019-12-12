local F, C = unpack(select(2, ...))

tinsert(C.themes["AuroraClassic"], function()
	F.ReskinPortraitFrame(BattlefieldFrame, 15, -15, -35, 73)
	F.ReskinScroll(BattlefieldListScrollFrameScrollBar)
	F.Reskin(BattlefieldFrameJoinButton)
	F.Reskin(BattlefieldFrameCancelButton)
	BattlefieldFrameZoneDescription:SetTextColor(1, 1, 1)
end)