//function SelectionCourierUpdate(msg) {
//    var needCourier = msg.newCourier;
//    var selectedEntities = GetSelectedEntities();
//    var selectionCounter = selectedEntities.length;
//    var removeTatget = msg.removeCourier;
//
//    var haveCourierInSelect = selectedEntities.some(function(e) { return Entities.IsCourier(e) });
//
//    Selection_Remove({entities:removeTatget})
//
//    if (haveCourierInSelect && selectionCounter < 2){
//        Selection_New({ entities:needCourier });
//    }else if(haveCourierInSelect){
//        Selection_Add({ entities:needCourier });
//    }
//}
//
//function OverrideDotaCourierUI() {
//    GameEvents.Subscribe( "selection_courier_update", SelectionCourierUpdate);
//    var selectCourietButton = FindDotaHudElement('SelectCourierButton')
//    var deliverItemsButton = FindDotaHudElement('DeliverItemsButton')
//
//    selectCourietButton.SetPanelEvent("onactivate", function () {
//        GameEvents.SendCustomGameEventToServer("courier_custom_select", {})
//    })
//    deliverItemsButton.SetPanelEvent("onactivate", function () {
//        GameEvents.SendCustomGameEventToServer("courier_custom_select_deliever_items", {})
//    })
//}

function OverrideDotaNeutralItemsShop() {
	var shop_grid_1 = $.GetContextPanel().GetParent().GetParent().GetParent().FindChildTraverse("GridNeutralsCategory")
	if(shop_grid_1) {
		shop_grid_1.style.overflow = "squish scroll"
	}
}

//function OverrideDotaTeleportNeutralItemsInStash() {
//    var teleportNeutralItems = FindDotaHudElement('TeleportToNeutralStash')
//
//	if (teleportNeutralItems != null && Object.keys(teleportNeutralItems).length > 2){
//		teleportNeutralItems.SetPanelEvent("onactivate", function () {
//			GameEvents.SendCustomGameEventToServer("drop_neutral_item_on_base", {})
//		})
//    }
//}

(function () {
    OverrideDotaNeutralItemsShop();
    //GameEvents.Subscribe( "override_dota_teleport_neutral_items_in_stash", OverrideDotaTeleportNeutralItemsInStash);
})();