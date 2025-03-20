--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onDrop(x, y, draginfo)
    return ItemManager.handleAnyDrop(getDatabaseNode(), draginfo);
end

function actionDamage(draginfo)
	local node = getDatabaseNode();
	local rActor = ActorManager.resolveActor(DB.getChild(node, "..."));
	ActionDamage.performRoll(draginfo, rActor, ActionDamage.getDamageAction(node));
end
