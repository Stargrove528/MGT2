--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
    local sAsset = DB.getText(window.getDatabaseNode(), "image", "");
    if sAsset ~= "" then
        ctrl = window.image;

        local nAssetX, nAssetY = Interface.getAssetSize(sAsset);
        local nMaxWidth = 250;
        local nMaxLength = 500;
        if nAssetX > nMaxWidth then
            local scale = nAssetX / nMaxWidth;
            nAssetX = nMaxWidth;
            nAssetY = nAssetY / scale;
        end
        if nAssetY > nMaxLength then
            nAssetY = nMaxLength;
        end

        ctrl.setAnchoredWidth(nAssetX);
        ctrl.setAnchoredHeight(nAssetY);
        ctrl.setAsset(sAsset);
        ctrl.setAnchor("left", "", "center", "absolute", tonumber("-" .. nAssetX/2));
        ctrl.setAnchor("top", "columnanchor", "bottom", "relative", 10);
        ctrl.setVisible(true);

        local sLinkClass, sLinkRecord = DB.getValue(window.getDatabaseNode(), "imagelink", "");
        if (sLinkClass ~= "") and (sLinkRecord ~= "") then
            window.createControl("linkc_refblock_image_clickcapture", "imagelink");
        end
    end
end