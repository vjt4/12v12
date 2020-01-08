itemPanels = []

function NeutralItemPickedUp( data ) {
	if ( itemPanels[data.item] ) {
		return
	}

	let item = $.CreatePanel( "Panel", $( "#ItemsContainer" ), "" )
	item.BLoadLayoutSnippet( "NewItem" )
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

	itemPanels[data.item] = true

	$.Schedule( 10, function() {
		item.DeleteAsync( 0 )
		itemPanels[data.item] = false
	} )
}

GameEvents.Subscribe( "neutral_item_picked_up", NeutralItemPickedUp )