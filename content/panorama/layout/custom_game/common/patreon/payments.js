let donation_target_dropdown;
let paymentTargetID = Game.GetLocalPlayerID();
let lastConfirmedDonationTarget = Game.GetLocalPlayerID();

function setPaymentWindowVisible(visible) {
	GameEvents.SendCustomGameEventToServer('patreon:payments:window', { visible });
	$('#PaymentWindow').visible = visible;
	$('#SupportButtonPaymentWindow').checked = visible;
	$('#PaymentConfirmationContainer').visible = visible;
	lastConfirmedDonationTarget = Game.GetLocalPlayerID();
	if (visible) {
		updatePaymentWindow();
		donation_target_dropdown.enabled = true;
	} else {
		$('#PaymentConfirmationContainer').visible = visible;
		donation_target_dropdown.enabled = false;
	}
}

/** @param {'success' | 'loading' | { error: string }} status */
function setPaymentWindowStatus(status) {
	var isError = typeof status === 'object';
	$('#PaymentWindowBody').visible = status === 'success';
	$('#PaymentWindowLoader').visible = status === 'loading';
	$('#PaymentWindowError').visible = isError;
	if (isError) {
		$('#PaymentWindowErrorMessage').text = status.error;
	}
}

function togglePaymentWindowVisible() {
	setPaymentWindowVisible(!$('#PaymentWindow').visible);
}

function ShowPaymentConfirmationWindow() {
	$('#PaymentConfirmationAvatar').steamid = Game.GetPlayerInfo(paymentTargetID).player_steamid;
	$('#PaymentConfirmationAvatarLabel').text = Players.GetPlayerName(paymentTargetID);
	$('#PaymentConfirmationContainer').style.visibility = 'visible';
}

function ConfirmPaymentTarget() {
	$('#PaymentConfirmationContainer').style.visibility = 'collapse';
	lastConfirmedDonationTarget = paymentTargetID;
	updatePaymentWindow()
}

function ResetPaymentTarget() {
	$('#PaymentConfirmationContainer').style.visibility = 'collapse';
}

const createPaymentRequest = createEventRequestCreator('patreon:payments:create');

let paymentWindowUpdateListener;
let paymentWindowPostUpdateTimer;
function updatePaymentWindow() {
	if (paymentTargetID != lastConfirmedDonationTarget && paymentTargetID != Game.GetLocalPlayerID()) {
		ShowPaymentConfirmationWindow();
		return;
	}

	if (paymentWindowUpdateListener != null) {
		GameEvents.Unsubscribe(paymentWindowUpdateListener);
		paymentWindowUpdateListener = null;
	}

	if (paymentWindowPostUpdateTimer != null) {
		$.CancelScheduled(paymentWindowPostUpdateTimer);
		paymentWindowPostUpdateTimer = null;
	}

	setPaymentWindowStatus('loading');

	var provider;
	for (var child of $('#PaymentWindowProviders').Children()) {
		if (child.checked) {
			provider = child.GetAttributeString("value", undefined);
		}
	}

	var paymentKind;
	for (var child of $('#PaymentWindowPaymentKinds').Children()) {
		if (child.checked) {
			paymentKind = child.GetAttributeString("value", undefined);
		}
	}

	const requestData = { provider, paymentKind, paymentTargetID };
	paymentWindowUpdateListener = createPaymentRequest(requestData, (response) => {
		if (response.url != null) {
			$('#PaymentWindowBody').SetURL(response.url);
			paymentWindowPostUpdateTimer = $.Schedule(1, () => {
				paymentWindowPostUpdateTimer = undefined;
				setPaymentWindowStatus('success');
			});
		} else {
			setPaymentWindowStatus({ error: response.error || 'Unknown error' });
		}
	});
}

function openUpgradePaymentWindow() {
	$('#PaymentWindowPaymentKinds').visible = false;
	$('#PaymentWindowPaymentKindsUpgradeTo2').checked = true;
	setPaymentWindowVisible(true);
}

function openPurchasePaymentWindow(value) {
	for (var child of $('#PaymentWindowProviders').Children()) {
		if (child.GetAttributeString("value", undefined) === value) {
			child.checked = true;
		}
	}

	setPaymentWindowVisible(true);
}

GameEvents.Subscribe('patreon:payments:update', (response) =>  {
	if (response.error) {
		setPaymentWindowStatus({ error: response.error });
	} else {
		setPaymentWindowVisible(false);
	}
});

GameEvents.Subscribe("patreon:gift:notification", (data) => {
	$("#GiftNotificationAvatar").steamid = Game.GetPlayerInfo(data.playerId).player_steamid;
	$("#GiftNotificationName").text = Players.GetPlayerName(data.playerId);
	$("#GiftNotificationLabel").text = $.Localize("#received_gift_" + data.level);
	$("#GiftNotificationPanel").style.opacity = 1;

	Particles.CreateParticle(
		`particles/patreon_gift_tier_${data.level}.vpcf`,
		ParticleAttachment_t.PATTACH_EYES_FOLLOW,
		0,
	);
	Game.EmitSound("Waitingforplayers_Boost_Shared");
	Game.EmitSound("Loot_Drop_Stinger_Rare");

	$.Schedule(8, () => {
		$("#GiftNotificationPanel").style.opacity = 0;
	});
});

function UpdatePaymentTargetList(patreonData) {
	if (donation_target_dropdown) {
		for(var id = 0; id <= 23; id++) {
			if (Players.IsValidPlayerID(id)) {
				if (patreonData[id] && patreonData[id].level > 0) {
					var this_player_option = $('#PatreonOption' + id);
					if (this_player_option) {
						this_player_option.DeleteAsync(0)
					}
				}
			}
		}
	} else {
		var dropdown_parent = $('#PaymentWindowUserSelectorContainer');
		donation_target_dropdown = $.CreatePanel('DropDown', dropdown_parent, 'PaymentWindowDropDown');
		var layout_string = '<root><DropDown style="margin-left: 5px;" oninputsubmit="updatePaymentWindow()" >';
		var local_id = Game.GetLocalPlayerID();

		layout_string += `<Label text="${Players.GetPlayerName(local_id)}" id="PatreonOption${local_id}" onmouseover="UpdatePaymentTarget(${local_id})" />`;

		for (var id = 0; id <= 23; id++) {
			if (Players.IsValidPlayerID(id) && id != local_id) {
				if (!patreonData[id] || patreonData[id].level <= 0) {
					layout_string += `<Label text="${Players.GetPlayerName(id)}" id="PatreonOption${id}" onmouseover="UpdatePaymentTarget(${id})" />`;
				}
			}
		}
		layout_string = layout_string + '</DropDown></root>';
		donation_target_dropdown.BLoadLayoutFromString(layout_string, false, true);

		donation_target_dropdown.SetSelected("PatreonOption" + local_id);
		UpdatePaymentTarget(local_id);
	}
}

function UpdatePaymentTarget(id) {
	$('#PaymentWindowAvatar').steamid = Game.GetPlayerInfo(id).player_steamid;
	paymentTargetID = id;
	if (paymentTargetID == Game.GetLocalPlayerID()) {
		lastConfirmedDonationTarget = Game.GetLocalPlayerID();
	}
}

setPaymentWindowVisible(false);
