function hiteffect( ent, dmginfo)


	if (ent:GetClass() == "prop_ragdoll" ) then

		local effect = EffectData()  
		local origin = dmginfo:GetDamagePosition()
		effect:SetOrigin( origin )
		 util.Effect( "bloodimpact", effect ) 
		local startp = dmginfo:GetDamagePosition()
       		local traceinfo = {start = startp, endpos = startp - Vector(0,0,50), filter = ent, mask = MASK_NPCWORLDSTATIC}
        	local trace = util.TraceLine(traceinfo)
        	local todecal1 = trace.HitPos + trace.HitNormal
        	local todecal2 = trace.HitPos - trace.HitNormal
        	 

	end

end
	

hook.Add("EntityTakeDamage", "holyshit", hiteffect)