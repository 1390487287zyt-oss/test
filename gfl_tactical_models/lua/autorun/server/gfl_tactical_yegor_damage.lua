hook.Add("EntityTakeDamage", "GFLTacticalYegorBulletDamage", function(_, damage)
    if not damage:IsBulletDamage() then return end

    local attacker = damage:GetAttacker()
    if not IsValid(attacker) or not attacker:IsNPC() then return end

    local multiplier = attacker.GFLTacticalBulletDamageScale
    if multiplier then
        damage:ScaleDamage(multiplier)
    end
end)
