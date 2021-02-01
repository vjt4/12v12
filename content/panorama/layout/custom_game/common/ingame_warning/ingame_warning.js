function CloseWarning(panelName) {
	$("#" + panelName).SetHasClass("hide", true);
}
function ScheludeCloseWarning(time, panelName) {
	$.Schedule(time, () => {
		CloseWarning(panelName);
	});
}

function OpenFeedback() {
	FindDotaHudElement("FeedbackHeaderRoot").GetParent().SetHasClass("show", true);
}

const TIMES_MULTIPLAYER = {
	sec: 86400,
	min: 1440,
	hour: 24,
	day: 1,
};
const COOLDOWN_FOR_RESET_MMR_BY_SUPP_LEVEL = {
	1: 14,
	2: 0,
};

function GetCooldownTimeForResetMmr(endDate, cooldownForSuppLevelInDays) {
	let format = "";
	let timeLeft = (new Date(endDate) - new Date()) / 864e5;
	timeLeft += cooldownForSuppLevelInDays;
	Object.entries(TIMES_MULTIPLAYER).forEach(([_format, multiplayer]) => {
		if (timeLeft > 1 / multiplayer) {
			format = _format;
		}
	});
	return { format: format, timeLeft: timeLeft * TIMES_MULTIPLAYER[format] };
}

function ShowResetMmrWarning(data) {
	$("#WarningIngame_ResetMMR").SetHasClass("show", true);
	const resetMmrCooldownRoot = $("#ResetMmrCooldownRoot");
	const buttonResetMmr = $("#ButtonResetMmr");

	resetMmrCooldownRoot.SetHasClass("show", false);
	buttonResetMmr.SetHasClass("Blocked", false);

	if (data.resetDate != "") {
		const cooldown = GetCooldownTimeForResetMmr(
			data.resetDate,
			COOLDOWN_FOR_RESET_MMR_BY_SUPP_LEVEL[data.suppLevel],
		);
		if (cooldown.timeLeft) {
			resetMmrCooldownRoot.SetHasClass("show", true);
			$("#ResetMmrCooldown").text = $.Localize("reset_mmr_cooldown").replace(
				"##cooldown_value##",
				$.Localize("boost_time_left_" + cooldown.format).replace("##time##", Math.floor(cooldown.timeLeft)),
			);
			buttonResetMmr.SetHasClass("Blocked", true);
		}
	}
}
function CloseResetMmr() {
	$("#WarningIngame_ResetMMR").SetHasClass("show", false);
}
function ResetMmrRequest() {
	if ($("#ButtonResetMmr").BHasClass("Blocked")) return;
	CloseResetMmr();
	GameEvents.SendCustomGameEventToServer("ResetMmrRequest", {});
}
(function () {
	GameEvents.Subscribe("show_reset_mmr", ShowResetMmrWarning);
})();
