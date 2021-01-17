"use strict";

function onClose() {
	$("#Leaderboard").visible = false;
}

function getTableRecord(record, parent, id) {
	let panel = $.CreatePanel("Panel", parent, id);
	panel.BLoadLayoutSnippet("TableRecord");

	panel.FindChildTraverse("Rank").text = record.rank;
	panel.FindChildTraverse("PlayerAvatar").steamid = record.steamId;
	panel.FindChildTraverse("PlayerUserName").steamid = record.steamId;
	panel.FindChildTraverse("Rating").text = record.rating;

	return panel;
}

function updateTable(players) {
	let body = $("#TableBody");
	body.RemoveAndDeleteChildren();

	let localSteamId = Game.GetLocalPlayerInfo().player_steamid;
	players.forEach((player, i) => {
		let panel = getTableRecord(player, body);
		if (player.steamId == localSteamId) panel.AddClass("local");
	});
}

function updateLocalPlayer(player) {
	let localPlayer = $("#LocalPlayer");
	localPlayer.RemoveAndDeleteChildren();

	getTableRecord(player, localPlayer);
}

function testLeaderboard() {
	let leaderboard = [];
	for (let i = 0; i < 100; i++) {
		leaderboard.push({
			rank: i,
			steamId: /*"76561198057976123",*/ "76561198143905703",
			rating: 2000,
		});
	}

	updateTable(leaderboard);
}

(function () {
	$("#Leaderboard").visible = false;
	const leaderboardButton = _AddMenuButton("OpenLeaderboard");
	CreateButtonInTopMenu(
		leaderboardButton,
		() => {
			let panel = $("#Leaderboard");
			panel.visible = !panel.visible;
		},
		() => {
			$.DispatchEvent("DOTAShowTextTooltip", leaderboardButton, "#leaderboard");
		},
		() => {
			$.DispatchEvent("DOTAHideTextTooltip");
		},
	);

	SubscribeToNetTableKey("game_state", "leaderboard", (leaderboardObj) => {
		let leaderboard = Object.values(leaderboardObj);
		if (leaderboard.length == 0) return;

		leaderboard.forEach((r, i) => (r.rank = i + 1));

		updateTable(leaderboard);
	});

	SubscribeToNetTableKey("game_state", "player_ratings", (ratingsObj) => {
		let localSteamId = Game.GetLocalPlayerInfo().player_steamid;
		let ratings = Object.values(ratingsObj).filter((r) => r.steamId == localSteamId);

		if (ratings.length == 0) return;

		updateLocalPlayer(ratings[0]);
	});
})();
