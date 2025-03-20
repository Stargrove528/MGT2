--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
    local sAsset = DB.getText(window.getDatabaseNode(), "image", "");
    if sAsset ~= "" then
        ctrl = window.createControl("image_refblock", "image");

        local nAssetX, nAssetY = Interface.getAssetSize(sAsset);

        if nAssetX > 320 then
            local scale = nAssetX / 320;
            nAssetX = 320;
            nAssetY = nAssetY / scale;
        end

        ctrl.setAnchoredWidth(nAssetX);
        ctrl.setAnchoredHeight(nAssetY);
        ctrl.setAsset(sAsset);
        ctrl.setAnchor("left", "", "center", "absolute", tonumber("-" .. nAssetX/2));
        ctrl.setAnchor("top", "spacer", "bottom", "relative", 10);
        ctrl.setVisible(true);

        local sLinkClass, sLinkRecord = DB.getValue(window.getDatabaseNode(), "imagelink", "");
        if (sLinkClass ~= "") and (sLinkRecord ~= "") then
            window.createControl("linkc_refblock_image_clickcapture", "imagelink");
        end
    end
end