function HighFiveActivate() {
	GameEvents.SendCustomGameEventToServer( "high_five_activate", { unit: Players.GetLocalPlayerPortraitUnit() } )
}

function HighFiveOver() {
	$.DispatchEvent( "DOTAShowAbilityTooltip", $( "#HighFiveButton" ), "high_five" );
}

function HighFiveOut() {
	$.DispatchEvent( "DOTAHideAbilityTooltip", $( "#HighFiveButton" ) );
}

function Update() {
	var ability = Entities.GetAbilityByName( Players.GetLocalPlayerPortraitUnit(), "high_five" )
	var panel = $( "#HighFive" )
	
	if ( ability != -1 ) {
		panel.style.visibility = "visible"

		var cooldown_panel = $( "#Cooldown" )

		if ( !Abilities.IsCooldownReady( ability ) ) {
			cooldown_panel.style.visibility = "visible"

			var remaining = Abilities.GetCooldownTimeRemaining( ability )

			$( "#CooldownText" ).text = Math.floor( remaining )

			/*var progress = ( -360 * ( remaining / Abilities.GetCooldownLength( ability ) ) ).toString()

			$( "#CooldownBackground" ).style.clip = "radial( 50% 50%, 0deg, " + progress + "deg )"*/
		} else {
			cooldown_panel.style.visibility = "collapse"
		}
	} else {
		panel.style.visibility = "collapse"
	}

	$.Schedule( 1 / 30, Update )
}

Update()