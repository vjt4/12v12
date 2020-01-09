itemPanels = []
droppedItems = []

$( "#ItemsContainer" ).RemoveAndDeleteChildren()

function NeutralItemPickedUp( data ) {
	if ( itemPanels[data.item] ) {
		return
	}

	let item = $.CreatePanel( "Panel", $( "#ItemsContainer" ), "" )
	item.BLoadLayoutSnippet( "NewItem" )
	item.AddClass( "Slide" )
	item.FindChildTraverse( "ItemImage" ).itemname = Abilities.GetAbilityName( data.item )
	item.FindChildTraverse( "ButtonKeep" ).SetPanelEvent( "onactivate", function() {
		item.visible = false
	} )
	item.FindChildTraverse( "ButtonDrop" ).SetPanelEvent( "onactivate", function() {
		GameEvents.SendCustomGameEventToServer( "neutral_item_drop", {
			item: data.item
		} )
		item.visible = false
	} )

	item.FindChildTraverse( "Countdown" ).AddClass( "Active" )

	itemPanels[data.item] = true

	$.Schedule( 10, function() {
		item.RemoveClass( "Slide" )
		item.DeleteAsync( 0.3 )
		itemPanels[data.item] = false
	} )
}

function NeutralItemDropped( data ) {
	let item = $.CreatePanel( "Panel", $( "#ItemsContainer" ), "" )
	item.BLoadLayoutSnippet( "TakeItem" )
	item.AddClass( "Slide" )
	item.FindChildTraverse( "ItemImage" ).itemname = Abilities.GetAbilityName( data.item )
	item.FindChildTraverse( "ButtonTake" ).SetPanelEvent( "onactivate", function() {
		GameEvents.SendCustomGameEventToServer( "neutral_item_take", {
			item: data.item
		} )
	} )
	item.FindChildTraverse( "CloseButton" ).SetPanelEvent( "onactivate", function() {
		item.visible = false
	} )

	item.FindChildTraverse( "Countdown" ).AddClass( "Active" )

	droppedItems[data.item] = item

	$.Schedule( 10, function() {
		if ( droppedItems[data.item] ) {
			item.RemoveClass( "Slide" )
			item.DeleteAsync( 0.3 )
			droppedItems[data.item] = false
		}
	} )
}

function NeutralItemTaked( data ) {
	if ( droppedItems[data.item] ) {
		droppedItems[data.item].DeleteAsync( 0 )
		droppedItems[data.item] = false

		let taked = $.CreatePanel( "Panel", $( "#ItemsContainer" ), "" )
		taked.BLoadLayoutSnippet( "WhoTakedItem" )
		taked.AddClass( "Slide" )
		taked.FindChildTraverse( "ItemImage" ).itemname = Abilities.GetAbilityName( data.item )
		taked.FindChildTraverse( "HeroImage" ).heroname = Players.GetPlayerSelectedHero( data.player )

		$.Schedule( 10, function() {
			taked.RemoveClass( "Slide" )
			taked.DeleteAsync( 0.3 )
		} )
	}
}

GameEvents.Subscribe( "neutral_item_taked", NeutralItemTaked )
GameEvents.Subscribe( "neutral_item_dropped", NeutralItemDropped )
GameEvents.Subscribe( "neutral_item_picked_up", NeutralItemPickedUp )