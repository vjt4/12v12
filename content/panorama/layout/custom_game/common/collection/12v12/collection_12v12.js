(function () {
	if (FindDotaHudElement("CollectionTopButton") != undefined) return;
	const collectionButton = _AddMenuButton("CollectionTopButton");
	CreateButtonInTopMenu(
		collectionButton,
		() => {
			ToggleMenu("CollectionCHC");
		},
		() => {
			$.DispatchEvent("DOTAShowTextTooltip", collectionButton, "#TopMenuIcon_Collection_message");
		},
		() => {
			$.DispatchEvent("DOTAHideTextTooltip");
		},
	);
})();