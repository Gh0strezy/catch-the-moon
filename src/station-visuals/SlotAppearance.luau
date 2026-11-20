-- Server-side presentation hook. Ownership, price and authorization belong to the caller.
local SlotAppearance={}
function SlotAppearance.setUnlocked(slot,unlocked)
	assert(type(unlocked)=="boolean","Expected unlocked state")
	slot.Halo.Material=if unlocked then Enum.Material.Neon else Enum.Material.Metal
	slot.Halo.Color=Color3.fromHex(if unlocked then "77DAD5" else "5D7386")
	slot.Emitter.Color=Color3.fromHex(if unlocked then "739CAC" else "374A60")
	slot.LockBar.Transparency=if unlocked then 1 else 0
	slot:SetAttribute("Unlocked",unlocked)
end
return SlotAppearance
