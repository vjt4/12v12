var hasPatreonStatus = Game.IsInToolsMode();
var isPatron = false;
var patreonLevel = 0
var offPatreonButton  = true
var offVOIconButton  = true

$( "#PatreonPerksContainer" ).RemoveAndDeleteChildren()

class PatreonPerk {
	constructor( name, level, overrideImage ) {
		this.panel = $.CreatePanel( "Panel", $( "#PatreonPerksContainer" ), "" )
		this.panel.BLoadLayoutSnippet( "PatreonPerk" )

		this.panel.FindChildTraverse( "PatreonPerkImage" ).SetImage( overrideImage || "file://{resources}/layout/custom_game/common/patreon/perks/" + name + ".png" )

		this.panel.FindChildTraverse( "PatreonPerkTitle" ).text = $.Localize( "#" + name )
		this.panel.FindChildTraverse( "PateonPerkDescription" ).text = $.Localize( "#" + name + "_description" )

		this.access = this.panel.FindChildTraverse( "PatreonPerkAccess" )
		this.level = level
		this.UpdateLevel()
	}

	UpdateLevel() {
		if ( patreonLevel >= this.level ) {
			this.access.text = $.Localize( "available_perk" )
			this.access.SetHasClass( "Available", true )
		} else {
			if ( this.level < 2 ) {
				this.access.text = ""
			} else {
				this.access.text = $.Localize( "high_tier_supporter_perk" )
			}
			this.access.SetHasClass( "Available", false )
		}
	}
}

GameEvents.Subscribe('is_local_server', function() {
	$('#LocalServerWarningContainer').style.visibility = 'visible';
	$('#LocalServerWarningContainer').style.opacity = '1.0';
});

function CloseLocalServerWarning() {
	$('#LocalServerWarningContainer').style.visibility = 'collapse';
}

function Divider() {
	let panel = $.CreatePanel( "Panel", $( "#PatreonPerksContainer" ), "" )
	panel.AddClass( "Divider" )
}

function OnPatreonButtonPressed() {
    var panel = $('#PatreonWindow');

    panel.visible = !panel.visible;
}

var shouldHideNewMethodsAnnouncement = false;
function hideNewMethodsAnnouncement() {
	shouldHideNewMethodsAnnouncement = true;
	updatePatreonButton();
}

function updatePatreonButton() {
	// TODO: Either remove full button, or revert this change
		var minimizePatreonButton = true;
		$('#PatreonButtonPanel').visible = hasPatreonStatus;
		$('#PatreonButton').visible = !minimizePatreonButton;
	if (offPatreonButton){
		$('#PatreonButtonSmallerImage').visible = minimizePatreonButton;
	}
	// Show icon only when chat wheel is loaded as it's not a common module yet
	if (offVOIconButton){
		$('#VOIcon').visible = Boolean(GameUI.CustomUIConfig().chatWheelLoaded) && Game.GetDOTATime(false, false) <= 120;
	}
	if (Game.GetDOTATime(false, false) > 120){
		$('#CloseVOIconButton').visible = false
	}
	$('#NewMethodsAnnouncement').visible = !shouldHideNewMethodsAnnouncement && !isPatron && $.Language() !== 'russian' && Game.GetDOTATime(false, false) <= 120;
}

function SetPatreonLevel( level ) {
	patreonLevel = level

	let visible1 = false
	let visible2 = false
	let visible3 = false
	let visible4 = false
	let visible5 = false

	if ( level < 1 ) {
		visible1 = true
		visible2 = true
	} else {
		if ( level < 2 ) {
			visible3 = true
		} else {
			visible4 = true
		}

		visible5 = true
	}
	$( "#IsNotPatreonText" ).visible = visible1
	$( "#PatreonSupportButtons" ).visible = visible2
	$( "#PatreonSupporter" ).visible = visible3
	$( "#PatreonSupporterHigh" ).visible = visible4
	$( "#ThanksText" ).visible = visible5
}

function ClosePatreonButton() {
	$("#PatreonButtonSmallerImage").visible = false
	$("#ClosePatreonButton").visible = false
	offPatreonButton = false
	$("#CloseVOIconButton").style.marginRight = "0px";
}

function ShowClosePatreonButton() {
	$("#ClosePatreonButton").visible = true
}

function HideClosePatreonButton() {
	$("#ClosePatreonButton").visible = false
}

function ShowVOIconButton() {
	var panel = $("#VOIcon");
	$.DispatchEvent( 'DOTAShowTextTooltip', panel, $.Localize('#votooltip'));
	$("#CloseVOIconButton").visible = true
}

function HideVOIconButton() {
	var panel = $("#VOIcon");
	$.DispatchEvent( 'DOTAHideTextTooltip', panel);
	$("#CloseVOIconButton").visible = false
}

function CloseVOIconButton() {
	$("#VOIcon").visible = false
	$("#CloseVOIconButton").visible = false
	offVOIconButton = false
}

new PatreonPerk( "our_thanks_and_appreciation", 1 )
Divider()
new PatreonPerk( "supporter_perks_low", 1 )
Divider()
new PatreonPerk( "first_pick_low", 1 )
Divider()
new PatreonPerk( "instant_transfer", 1 )
Divider()
new PatreonPerk( "immune_kick_troll", 1 )
Divider()

new PatreonPerk( "first_pick_high", 2 )
Divider()
new PatreonPerk( "supporter_perks_high", 2 )

SetPatreonLevel(0);

SubscribeToNetTableKey('game_state', 'patreon_bonuses', function (data) {
	UpdatePaymentTargetList(data);

	var status = data[Game.GetLocalPlayerID()];
	if (!status) return;

	hasPatreonStatus = true;
	isPatron = status.level > 0;
	$.GetContextPanel().SetHasClass('IsPatron', isPatron);
	updatePatreonButton();

	SetPatreonLevel( status.level )

	var isAutoControlled = status.endDate != null;
	$('#PatreonSupporterUpgrade').visible = isAutoControlled && status.level < 2;
	$('#PatreonSupporterStatusExpiriesIn').visible = isAutoControlled;
	if (isAutoControlled) {
		var endDate = new Date(status.endDate);
		var daysLeft = Math.ceil((endDate - Date.now()) / 1000 / 60 / 60 / 24);
		$('#PatreonSupporterStatus').SetDialogVariable('support_days_left', daysLeft);
		$('#PatreonSupporterStatus').SetDialogVariable('support_end_date', formatDate(endDate));
	}
});

setInterval(updatePatreonButton, 1000);
$('#PatreonWindow').visible = false;
