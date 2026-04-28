local DMGINFO = FindMetaTable("CTakeDamageInfo")
 
local COLL_CACHE = {}
 
local vec_max = Vector(1, 1, 1)
local vec_min = -vec_max
 
function DMGINFO:GetHitPhysBone(ent)
    local mdl = ent:GetModel()
 
    local colls = COLL_CACHE[mdl]
    if !colls then
        colls = CreatePhysCollidesFromModel(mdl)
        COLL_CACHE[mdl] = colls
    end
 
    local dmgpos = self:GetDamagePosition()
 
    -- Simple approach: find the closest physics bone to the damage position
    local closest_phys_bone = nil
    local closest_dist = math.huge
    
    for phys_bone, coll in pairs(colls) do
        phys_bone = phys_bone - 1
        local bone = ent:TranslatePhysBoneToBone(phys_bone)
        local pos, ang = ent:GetBonePosition(bone)
        
        local dist = pos:DistToSqr(dmgpos)
        if dist < closest_dist then
            closest_dist = dist
            closest_phys_bone = phys_bone
        end
    end
    
    return closest_phys_bone
end
 
 
local good_bones = {
    "ValveBiped.Bip01_Head1",
    "ValveBiped.Bip01_Neck1",
    "ValveBiped.Bip01_R_Calf",
    "ValveBiped.Bip01_L_Calf",
    "ValveBiped.Bip01_R_Thigh",
    "ValveBiped.Bip01_L_Thigh",
    "ValveBiped.Bip01_R_Forearm",
    "ValveBiped.Bip01_L_Forearm",
    "ValveBiped.Bip01_R_Wrist",
    "ValveBiped.Bip01_L_Wrist",
    "ValveBiped.Bip01_R_UpperArm",
    "ValveBiped.Bip01_L_UpperArm",
    "ValveBiped.Bip01_R_Clavicle",
    "ValveBiped.Bip01_L_Clavicle",
    "ValveBiped.Bip01_Pelvis",
    "ValveBiped.Bip01_Spine",
    "ValveBiped.Bip01_Spine1",
    "ValveBiped.Bip01_Spine2",
    "ValveBiped.Bip01_Spine3",
    "ValveBiped.Bip01_Spine4",
    "ValveBiped.Bip01_R_Foot",
    "ValveBiped.Bip01_L_Foot",
}
 
function DMGINFO:GetHitBone_Ragdoll(ent)
    
    local min_dist
    local bone_idx
 
    for i = 0,ent:GetBoneCount()-1 do
        for _,v in ipairs(good_bones) do
            if ent:GetBoneName(i)==v then
                local dist = ent:GetBonePosition(i):DistToSqr(dmginfo:GetDamagePosition())
 
                if !min_dist or dist < min_dist then
                    min_dist = dist
                    bone_idx = i
                end
 
                break
            end
        end
    end
 
    return bone_idx
end
