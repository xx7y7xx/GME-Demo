/**************************************************************************
*   Copyright (C) 2013 by sanpolo CO.LTD                                  *
*                                                                         *
*   This file is part of GUtil.                                           *
*                                                                         *
*   GUtil is private software.                                            *
*                                                                         *
*   GUtil is distributed as the integration with glue.used for software   *
*   interact with glue.                                                   *
*                                                                         *
*   You should have received a copy of the GLUE License along with this   *
*   program.  If not, see <http://www.render001.com/licenses>.            *
*                                                                         *
*   GUtil website: http://www.render001.com/gutil                         *
**************************************************************************/

macroScript max_gmeditor
category:"Superpolo"
ButtonText:"Render" 
tooltip:"Spp max gmeditor" Icon:#("Maxscript", 2)
(

	G_Doc = undefined
	G_GlueHomePath = undefined
	
	/**
	 * XML Parser
	 */
	DotNet.LoadAssembly "System.Xml"
	struct XMLNode(
		Tag,
		Parent,
		DotNetNode,
		
		fn init dnNode = (
			DotNetNode = dnNode
			Tag = dnNode.LocalName
			Parent = dnNode.ParentNode
		),
		fn GetTag = (
			DotNetNode.Name
		),
		fn SetTag newTag =(
			try(DotNetNode.Name = newTag)catch(False)
		),
		fn GetText = (
			DotNetNode.InnerText
		), 
		fn SetText txt = (
			DotNetNode.InnerText = txt
		),
		fn AddAttribute attribute value = (
			DotNetNode.SetAttribute attribute value
		),
		fn GetAttribute attribute = (
			DotNetNode.GetAttribute attribute
		),
		fn SetAttributeValue attribute value = (
			DotNetNode.SetAttribute attribute value
		),
		fn DeleteAttribute attribute = (
			DotNetNode.RemoveAttribute attribute
		),
		fn GetAllAttributes = (
			ret = #()
			attribs = DotNetNode.Attributes
			for i = 0 to (attribs.Count - 1) do(
				t = #()
				item = (attribs.ItemOf i)
				append t item.Name
				append t item.Value
				append ret t
			)
			return ret
		),
		fn HasAttribute attribute =(
			DotNetNode.HasAttribute attribute
		),
		
		fn AppendNode newNode = (
			if classof newNode == XMLNode then(
				DotNetNode.AppendChild newNode.DotNetNode
				return True
			)else(False)
		),
		
		fn GetChild index = (
			dNode = DotNetNode.ChildNodes.ItemOf index
			if dNode.Name != "#text" then(
				newNode = XMLNode()
				newNode.init dnode
				newNode
			)else(return False)
		),
		fn GetChildren = (
			nodes = #()
			for i = 0 to (DotNetNode.ChildNodes.Count - 1) do(
				dNode = DotNetNode.ChildNodes.ItemOf i
				newNode = XMLNode()
				newNode.init dNode
				append nodes newNode
			)
			nodes
		),
		fn DeleteChild childNode = (
			if classof childNode == XMLNode then (
				DotNetNode.RemoveChild childNode.DotNetNode
				return True
			)else(False)
		)
	)

	struct XMLDocument ( 
		file = undefined,
		rootNode = undefined,
		dom = dotNetObject "System.Xml.XmlDocument",
		loaded = undefined,
		
		fn LoadXML pathToXml = (
			file = pathToXml
			doc = dom.Load file
			loaded = True
			True
		),
		
		fn SaveXML = (
			if loaded == True then(
				dom.Save file
				return True
			)else(False)
		),
		
		fn GetRootNode = (
			rootNode = XMLNode()
			rootNode.init dom.DocumentElement
			rootNode
		),
		fn getNewNode tag = (
			dNode=dom.CreateElement tag
			newNode=XMLNode()
			newNode.init dNode
			newNode
		),
		fn AppendNode newNode = (
			if classof newNode == XMLNode then(
				dom.AppendChild newNode.DotNetNode
				return True
			)else(False)
		),
		fn PrettySaveXML = (
			if loaded == True then(
				writer = dotNetClass "System.Xml.XmlTextWriter"
				wSettings = dotNetObject "System.Xml.XmlWriterSettings"
				wSettings.indent = True
				w = writer.create file wSettings
				--dom.writeTo w
				dom.writeContentTo w
				w.close()
				True
			)
		)
	)

	/**
	 * export to sps file format
	 */
	struct SPS_Exporter(
		filename = undefined,
		-- 3ds file path
		exportedFile = undefined,
		-- xml document object of xml file.
		xDoc = undefined,
		
		
		/**
		 * Help function to create xml node.
		  */
		
		-- Pre-declaration
		fn createObjectNode = (),
		fn createObjectsNode = (),
		
		fn createKdNode materialNode =
		(
			local kdNode = xDoc.getNewNode "kd"
			materialNode.AppendNode kdNode
			kdNode.AddAttribute "type" "constfloat3"
			kdNode.AddAttribute "r" "0.75"
			kdNode.AddAttribute "g" "0.75"
			kdNode.AddAttribute "b" "0.75"
		),
		
		fn createObjectNode meshname mid mattplPath =
		(
			-- get objects node.
			local sceneNode = xDoc.GetRootNode()
			local objectsNode = sceneNode.GetChild 0
			
			objectNode = xDoc.getNewNode "object"
			objectsNode.AppendNode objectNode
			--objectNode.AddAttribute "id" "47e473093c774a94a81c612cacec8044"
			--objectNode.AddAttribute "name" meshname
			--objectNode.AddAttribute "file" (meshname + ".obj")
			-- create material node <material>
			(
				materialNode = xDoc.getNewNode "material"
				objectNode.AppendNode materialNode
				print "[" + G_GlueHomePath + "]"
				if mid == undefined do
				(
					messagebox "material id is undefined, when create <material> node"
					return False
				)
				if mid == "" do
				(
					messagebox "material id is empty string, when create <material> node"
					return False
				)
				
				-- default template
				if mattplPath == False then
				(
					mattplPath = G_GlueHomePath + "\\gutil\\template\\whitematte.gmt"
				)
				materialNode.AddAttribute "id" (mid as String)
				materialNode.AddAttribute "template" mattplPath
				--createKdNode(materialNode)
			)
			return materialNode
		),

		fn createObjectsNode rNode exportedFile =
		(
			if exportedFile == undefined do
			(
				messagebox "file attribute in <objects> node is undefined!"
				return False
			)
			if exportedFile == "" do
			(
				messagebox "file attribute in <objects> node is empty string!"
				return False
			)
			objectsNode = xDoc.getNewNode "object"
			rNode.AppendNode objectsNode
			objectsNode.AddAttribute "optimize" "false"
			objectsNode.AddAttribute "file" exportedFile
			return objectsNode
		),

		fn createLightsNode rNode =
		(
			lightsNode = xDoc.getNewNode "lights"
			rNode.AppendNode lightsNode
			-- create envlight node <envlight>
			(
				envlightNode = xDoc.getNewNode "envlight"
				lightsNode.AppendNode envlightNode
				envlightNode.AddAttribute "type" "sky"
				envlightNode.AddAttribute "gain" "1.000000 1.000000 1.000000"
				envlightNode.AddAttribute "dir" "0.577350 0.577350 0.577350"
			)
		),
		
		fn createSceneNode =
		(
			local ret = False
			-- create root node <scene>
			rNode = xDoc.getNewNode "scene"
			xDoc.AppendNode rNode
			--rNode = xDoc.getRootNode()
			
			-- create objects node <objects>
			ret = createObjectsNode rNode exportedFile
			if ret == False do
			(
				messagebox "Failed to create <objects> node in <scene> node"
				return False
			)
			
			-- create lights node <lights>
			createLightsNode rNode

			ret = rNode
			
			return ret
		),
		
		fn init =
		(
			-- prepare xml file
			xDoc = XMLDocument()
			xDoc.file = filename
			xDoc.loaded = True
			
			-- create root node
			createSceneNode()
		),
		
		-- save xml docs to file.
		fn SaveFile =
		(
			xDoc.SaveXML()
		),
		
		fn onAddMesh meshname mid mattplPath =
		(
			-- create object node <object>
			local materialNode = createObjectNode meshname mid mattplPath
			if materialNode == False do
			(
				messagebox "Failed to create <object> node!"
				return False
			)
			return materialNode
		),
		
		fn onAddSubmesh = (
			return False
		)
	)

	struct JSON_Exporter(
		filename = undefined
	)
	
	-- texture: example: diffuse, specular
	-- type: example: bitmap, falloff
	-- filepath: example: D:\...\a.jpg
	fn onAddMaps materialNode texture type filepath =
	(
		local mapNode = G_Doc.getNewNode texture
		materialNode.AppendNode mapNode
		mapNode.AddAttribute "type" (type as String)
		mapNode.AddAttribute "file" filepath
	)
	
	fn pos2str pos =
	(
		local x = (pos.x as String)
		local y = (pos.y as String)
		local z = (pos.z as String)
		return (x + " " + y + " " + z)
	)
	
	fn createCameraNode camerasNode cam =
	(
		local campos = cam.pos
		--local viewpos = [0,0,-cam.targetDistance];
		--local targetpos = (viewpos * (inverse cam.transform) ) ; 
		local targetpos = cam.target.pos
		local updirect = cam.transform.row2
		
		local cameraNode = G_Doc.getNewNode "camera"
		camerasNode.AppendNode cameraNode
		cameraNode.AddAttribute "name" "default"
		cameraNode.AddAttribute "position" (pos2str(campos))
		cameraNode.AddAttribute "target" (pos2str(targetpos))
		cameraNode.AddAttribute "up" (pos2str(updirect))
		cameraNode.AddAttribute "focalDistance" "48.3693008"
	)
	
	fn createCamerasNode =
	(
		local sceneNode = G_Doc.GetRootNode()
		local camerasNode = G_Doc.getNewNode "cameras"
		sceneNode.AppendNode camerasNode
		camerasNode.AddAttribute "active" "0"
		return camerasNode
	)
	
/**
 * =======================================================================================
 */
	
	-- check if we have gmeditor install, and register it.
	fn checkGlueEnv =
	(
		local syspath = systemTools.getEnvVariable "PATH" 
		local existflag = matchPattern syspath pattern:"*gmedit*" ignoreCase:true
		if not existflag then(
			messagebox "Please install glue tools first!"
			return False
		)
		if maxfilepath == "" then
		(
			messagebox "Please open max file first!"
			return False
		)
	)

-- 
 ------------------------------------------------------------------------------------------- output obj ocs  ocm diffuse
	-- 

	fn dealmatex tex =
	(
		local texfile;
		case classof tex of
		(
			Falloff:
			(
				texfile = dealmatex tex.map1
				if texfile != false then 
					return texfile
				else 
				(
					return dealmatex tex.map2
				)
			)
			Bitmaptexture:
			(
                texfile = tex.filename
                --print texfile
                return texfile
				/* texfile = tex.filename
				if (doesfileexist texfile) then
					return texfile
				else
					return false */
			)
			UndefinedClass: return false
			default:
			(
				print ((classof tex) as string + "����ͼ����û�д���,����ϵ������Ա")
				return false
			)
		)
	)
	--����material diffuse color
	fn retmatColor mat =
	(
		case classof mat of
		(
			Blend: retmatColor mat.map1
			VRayMtlWrapper: retmatColor mat.BaseMtl
			VRayLightMtl:	
			(	
				return mat.color
			)
            VRayBlendMtl: (print("deal vrayblendmtl color"); return (retmatColor mat.basemtl);)
			UndefinedClass: return (color 128 128 128)
			default:
				return  mat.diffuse
		)
	)
	--����material�Ƿ�����ͼ,���޷���fasle
	fn retmatTex mat =
	(
		local texfile;
		case classof mat of
		(
			Blend: 
			(
				if mat.mask != undefined then
				(
					texfile = dealmatex mat.mask
				)
				if texfile != false then
					return texfile
				texfile = retmatTex mat.map1
				if texfile != false then
					return texfile
				texfile = retmatTex mat.map2
				if texfile != false then
					return texfile
				return false
			)
			VRayMtlWrapper: retmatTex mat.BaseMtl
			UndefinedClass: return false
            VRayMtl : return (dealmatex mat.texmap_diffuse)
			Standardmaterial : return (dealmatex mat.diffusemap)
            VRayLightMtl : return (dealmatex mat.texmap)
			VRayBlendMtl : (return (retmatTex (mat.basemtl)))
			VRayOverrideMtl : (return (retmatTex (mat.basemtl)))
			default:
				try(
					return  dealmatex mat.diffusemap
				)catch(print ("cant deal"+classof mat as string + mat.name); return false)
		)
	)
	
	fn dealv2s obj objmat arrIncrement p arrTexNum arrTexInfo = 
	(
		local tt;
		tt = Standardmaterial ()
		testflag = false
		local texfile
		texfile = retmatTex objmat
		if texfile != false then
		(
            --ָ����bitmap,����û�м�����ͼ
            if texfile == "" then(
                return false
            )
            --����������ͼ·��
            paths = getFilenamePath texfile
            if paths == "" then(
                texfile = (maxfilepath + filenameFromPath  texfile)
            )
            if not (doesfileexist texfile) then(
                --print(texfile + "not exist")
                return false
            )
            
            --curpath
            pfile = texfile
            paths = getFilenamePath texfile
            if paths != p then(
                pfile = p  + filenameFromPath texfile
                copyfile texfile (pfile)
            )
			tt.diffusemap = Bitmaptexture filename:pfile
		)
		else
		(
			local cl
			cl = retmatColor objmat
			local strname = cl.r as string + cl.g as string  + cl.b as string
			local idx = finditem arrTexNum strname
			local texfiles = ""
			if idx != 0 then 
				texfiles = arrTexInfo[idx]
			else
			(
				arrIncrement[1] += 1
				myBitmap = bitmap 32 32 color:[cl.r, cl.g,cl.b]
				texfiles =  (p  + "tex" + arrIncrement[1] as string + ".jpg")
				append arrTexInfo texfiles
				append arrTexNum strname
				myBitmap.filename = texfiles
				save myBitmap
				--
			)
			tt.diffusemap = Bitmaptexture filename: texfiles
		)
		return tt
	)

	fn v2s =
	(
		local arrTexInfo = #()
		local arrTexNum = #()
		local arrIncrement = #(0)
		local p = maxfilepath
		--p = "D:\\p\\aaaaa\\src\\diffuse\\"
		--makeDir p
		for o in geometry do 
		(
			if classof o.material == Multimaterial then 
			(
                nums = o.material.materialList.count
                for i = 1 to nums do(
                    id = o.material.materialIDList[i]
					local omat = o.material[id]
					if omat != undefined  do
					(
						local newmat = dealv2s o omat arrIncrement p arrTexNum arrTexInfo
	--                     if newmat == false then(
	-- 						--messagebox (o.name + "ģ�͵Ĳ���:" + omat.name  + " ��ͼ�Ҳ���")
	-- 						return  (o.name + "ģ�͵Ĳ���:" + omat.name  + " ��ͼ�Ҳ���\n")
	--                         --return false
	--                     )
						newmat.name = omat.name
						o.material [id] = newmat
						showTextureMap o.material[id]  on
					)
				)
			)
			else
			(	
				local omat = o.material
				if omat != undefined do
				(
					local newmat = dealv2s o omat arrIncrement p arrTexNum arrTexInfo
	--                 if newmat == false then(
	--                        return  (o.name + "ģ�͵Ĳ���:" + omat.name  + " ��ͼ�Ҳ���\n")
	--                 )
					newmat.name = omat.name
					o.material = newmat
					showTextureMap o.material on
				)
			)
			
		)
		actionMan.executeAction 0 "40807"
		return true
	)
-- 	v2s()
	
	
	
-- 	fn output_path =
-- 	(
-- 		getpath = maxfilepath
-- 		if getpath!=undefined then
-- 		(
-- 			getpath = getpath + "output\\"
-- 			makedir getpath
-- 		)
-- 		getpath
-- 	)
	
-- material name
-- material mesh
---------------------------------------------------------------detach by mat

-- get all geometry
	
fn getMaterialIDs obj =
(
	id_arr = #()
	mat = obj.mat
	submatNum = getNumSubMtls mat 
	for i in 1 to submatNum do
	(
		obj.selectByMaterial i
		the_faces = getFaceSelection obj
		if (the_faces as array).count != 0 do
		(
			append id_arr i
		)
	)
	id_arr
)





	-- data export to "gmedata", this folder is in the same dir of max file.
	fn createExportDataDir =
	(
		local getmaxP = maxfilepath
		local objP = getmaxP + "\\gmedata"
		makedir objP
		return objP
	)



--------------------------------------------------------------------------------- mat start
	
/* 	
fn set_mat = 
(
	cmdstr = "/C \"" +	cmd+" & matlist"
	ShellLaunch "cmd" cmdstr	
	
)	
  */
	fn get_tex_list theMat materialNode =
	(
		if theMat == undefined do
		(
			return False
		)
		
		print ("Current material : " + ((classof theMat) as String))
		
		-- only support standard material.
		if (classof theMat) == Standardmaterial do
		(
			if theMat.shaderType == 1 do
			(
				local maps = theMat.maps 
				for i=1 to maps.count do
				(
					if maps[i] != undefined do
					(
						case i of 
						(
							1:
							(
								onAddMaps materialNode "AmbientMap" (classof maps[i]) maps[i].fileName
							)
							2:
							(
								onAddMaps materialNode "diffuse" (classof maps[i]) maps[i].fileName
							)
							3:
							(
								onAddMaps materialNode "SpecularMap" (classof maps[i]) maps[i].fileName
							)
							4:
							(
								onAddMaps materialNode "SpecularLevelMap" (classof maps[i]) maps[i].fileName
							)
							5:
							(
								onAddMaps materialNode "GlossinessMap" (classof maps[i]) maps[i].fileName
							)
							6:
							(
								onAddMaps materialNode "SelfIllumMap" (classof maps[i]) maps[i].fileName
							)
							7:
							(
								onAddMaps materialNode "OpacityMap" (classof maps[i]) maps[i].fileName
							)
							8:
							(
								onAddMaps materialNode "FilterMap" (classof maps[i]) maps[i].fileName
							)
							9:
							(
								onAddMaps materialNode "BumpMap" (classof maps[i]) maps[i].fileName
							)
							10:
							(
								onAddMaps materialNode "ReflectionMap" (classof maps[i]) maps[i].fileName
							)
							11:
							(
								onAddMaps materialNode "RefractionMap" (classof maps[i]) maps[i].fileName
							)
							12:
							(
								onAddMaps materialNode "DisplacementMap" (classof maps[i]) maps[i].fileName
							)
							default:""
						)
						
					)
					
				)
			)
		)
		
		if (classof theMat) == VRayMtl do
		(
			if (classof theMat.texmap_diffuse) != Bitmaptexture do
			(
				print "only support bitmap."
				return False
			)
			onAddMaps materialNode "diffuse" "Bitmaptexture" theMat.texmap_diffuse.fileName
		)
	)
-- get_tex_list $

--------------------------------------------------------------------------------- mat end	

	-- do some processing after export to xml
	-- this xml has some material template info, so use gutil to repalce them
	-- and create a new *.sps file
	fn postprocess inputFile =
	(
		local cmd = "gutil.exe --file=" + inputFile + " expandmaterial"
		local startpath = G_GlueHomePath + "\\gutil"
		HiddenDOSCommand cmd startpath:startpath donotwait:false
	)

	fn get_attr_by_mesh obj = 
	(
-- 		act_id = activeMeditSlot 
-- 		act_m = meditMaterials[act_id]
		mat = obj.mat
		if mat != undefined do
		(
			attr = custAttributes.get mat 1
			if attr == undefined then
			(
				--messagebox (obj.name + "has no glue material")
				return False
			)
			p = attr.glueMat_path
			if p == "" do
			(
				return False
			)
			if p == undefined do
			(
				return False
			)
			return p
		)
	)
	

	
on execute do 
(
	-- must defined in this function for maxscript scope problem.
	struct Walker
	(
		fn walk2 exporter gmedataDir = 
		(
			-- export root node of all camera, if we create at least one camera in max.
			-- otherwise, not to export root node of camera.
			local bFirstCam = True
			local camerasNode
			
			-- rename all material name with a number.
			local curID = 0
			
			for obj in objects do(
				print (classOf(obj.mat) as string)
				local mat = obj.mat
				if classOf(mat) != UndefinedClass do
				(
					--print (classOf(OBJ) as string)
					--print OBJ.children.count
					submatNum = getNumSubMtls mat 
					if submatNum == 0 then
					(
						print "not multimaterial"
						--single material
						curID += 1
						mat.name = curID as string
						
						
						-- xxdebug = duplicated 
						(
							local mattplPath = get_attr_by_mesh obj
							local materialNode = exporter.onAddMesh obj.name curID mattplPath
							if materialNode == undefined then
							(
								messagebox "Failed to create mesh!"
								return False
							)
							get_tex_list mat materialNode
						)

						
					)
					else
					(
						print "multimaterial"
						--multi material
						for i in 1 to submatNum do
						(
							local m = getSubMtl mat i
							--print curID as string
							curID += 1
							m.name = curID as string
							
							
							
							-- xxdebug = duplicated 
							(
								local mattplPath = get_attr_by_mesh obj
								local materialNode = exporter.onAddMesh obj.name curID mattplPath
								if materialNode == undefined then
								(
									messagebox "Failed to create mesh!"
									return False
								)
								get_tex_list m materialNode
							)
							
						
						)
					)
				)
				
				if classOf(obj) == TargetCamera do
				(
					-- create <cameras> node at the first camera.
					if bFirstCam == True do
					(
						camerasNode = createCamerasNode()
						bFirstCam = False
					)
					createCameraNode camerasNode obj
				)
			)
		)
	)
	
	--
	-- check env
	--
	
	if checkGlueEnv() == False do
	(
		return False
	)
	
	--
	-- define global vars
	--
	
	G_GlueHomePath = systemTools.getEnvVariable "GLUE_HOME"
	G_Doc = undefined
	
	--
	-- define local vars
	--

	local gmedataDir = createExportDataDir()
	local maxspsFile = gmedataDir + "\\main.maxsps"
	local exportedFile = gmedataDir + "\\main.3ds"
	
	--
	-- exprt 3ds file
	--
	exportfile exportedFile #noPrompt selectedOnly: false
	
	--
	-- export maxsps file
	--
	
	-- create exporter for sps file format
	exporter = SPS_Exporter maxspsFile exportedFile
	-- create walker for max file format
	walker = Walker()

	exporter.init()
	G_Doc = exporter.xDoc

	-- walk all submesh in max and call processing code.
	walker.walk2 exporter gmedataDir

	exporter.SaveFile()
	
	-- post process of export.
	postprocess(maxspsFile)
	
	-- call gmeditor to render
	local cmd = "gmeditor.exe " + gmedataDir + "\\main.sps"
	local rundir = G_GlueHomePath + "\\gmeditor"
	HiddenDOSCommand cmd startpath:rundir donotwait:true
	
)
)

macroScript materialList
category:"Superpolo"
ButtonText:"Material" 
tooltip:"Spp material List" Icon:#("Maxscript", 2)
(
----------------------------------------------------------------------------- mat attribute start

	fn add_curntMat_attr =
	(
		-- get act mat in editor 
		act_id = activeMeditSlot 
		act_m = meditMaterials[act_id]
		id_count = getNumSubMtls act_m
		if id_count == 0 do
		(-- as a standard
			if (classof act_m) == standardmaterial do
			(
				attr_num = custAttributes.count act_m 
				if attr_num == 0 do
				(
					glue_ShaderType = attributes "glueShaderType"
					(
						parameters main rollout:glueShaderType
						(
							glueMaterial ui:sel_shader_type type:#string default:""
							glueMat_path type:#string 
						)
						rollout glueShaderType "glueShaderType" width:162 height:300
						(
							button sel_shader_type "ѡ�� Glue ��������" pos:[7,6] width:116 height:21 
							label mat_name_lbl2 "" pos:[169,4] width:94 height:23
							on sel_shader_type pressed  do
							(
								thePath = getOpenFileName()
								if thePath == undefined do
								(
									return False
								)
								glueMat_path = thePath
							)
						)-- end rollout
					)-- end attribute def
					custAttributes.add act_m glue_ShaderType 
				)-- end attr_num == 0
			)-- end standardmaterial
		)-- end id_count == 0	
		if id_count > 0 do
		(-- as a multimetirial
			if (classof act_m) == multimaterial do
			(
				for i= 1 to id_count do
				(
					actmm = act_m[i]
					if (classof actmm) == standardmaterial do
					(
						attr_num = custAttributes.count actmm 
						if attr_num == 0 do
						(
							glue_ShaderType = attributes "glueShaderType"
							(
								parameters main rollout:glueShaderType
								(
									glueMaterial ui:sel_shader_type type:#string default:""
									glueMat_path type:#string 
								)
								rollout glueShaderType "glueShaderType" width:162 height:300
								(
									button sel_shader_type "ѡ�� Glue ��������" pos:[7,6] width:116 height:21 
									label mat_name_lbl2 "" pos:[169,4] width:94 height:23
									on sel_shader_type pressed  do
									(
										thePath = getOpenFileName()
										if thePath == undefined do
										(
											return False
										)
										glueMat_path = thePath
									)
								)-- end rollout
							)-- end attribute def
							custAttributes.add actmm glue_ShaderType 
						)-- end attr_num == 0
					)-- end standardmaterial classof
				)-- end multimaterial loop
			)-- end multimaterial classof
		)-- end id_count > 0		
	)
	-- add_curntMat_attr() 
	
	fn add_glue_attr =
	(
	  isopen = matEditor.isopen()
	  if isopen == true then
	  (
		txt ="act_id = activeMeditSlot \n"
		txt +="act_m = meditMaterials[act_id]\n"
		txt +="id_count = getNumSubMtls act_m\n"
		txt +="if id_count == 0 do\n"
		txt +="(-- as a standard\n"
		txt +="	if (classof act_m) == standardmaterial do\n"
		txt +="	(\n"
		txt +="	attr_num = custAttributes.count act_m \n"
		txt +="	if attr_num == 0 do\n"
		txt +="	(\n"
		txt +="		glue_ShaderType = attributes \"glueShaderType\"\n"
		txt +="		(\n"
		txt +="			parameters main rollout:glueShaderType\n"
		txt +="			(\n"
		txt +="				glueMaterial ui:sel_shader_type type:#string default:\"\"\n"
		txt +="				glueMat_path type:#string \n"
		txt +="			)\n"
		txt +="			rollout glueShaderType \"glueShaderType\" width:162 height:300\n"
		txt +="			(\n"
		txt +="				button sel_shader_type \"ѡ�� Glue ��������\" pos:[7,6] width:116 height:21 \n"
		txt +="				label mat_name_lbl2 \"\" pos:[169,4] width:94 height:23\n"
		txt +="				on sel_shader_type pressed  do\n"
		txt +="				(\n"
		txt +="					thePath = getOpenFileName()\n"
		txt +="					if thePath == undefined do      \n"
		txt +="					(                               \n"
		txt +="						return False               \n"
		txt +="					)                               \n"
		txt +="					glueMat_path = thePath\n"
		txt +="				)\n"
		txt +="			)\n"
		txt +="		)\n"
		txt +="		custAttributes.add act_m glue_ShaderType \n"
		txt +="		)\n"
		txt +="	)\n"
		txt +=")\n"
		txt +="if id_count > 0 do\n"
		txt +="(-- as a multimetirial\n"
		txt +="	if (classof act_m) == multimaterial do\n"
		txt +="	(\n"
		txt +="	for i= 1 to id_count do\n"
		txt +="	(\n"
		txt +="		actmm = act_m[i]\n"
		txt +="		if (classof actmm) == standardmaterial do\n"
		txt +="		(\n"
		txt +="		attr_num = custAttributes.count actmm \n"
		txt +="		if attr_num == 0 do\n"
		txt +="		(\n"
		txt +="			glue_ShaderType = attributes \"glueShaderType\"\n"
		txt +="			(\n"
		txt +="				parameters main rollout:glueShaderType\n"
		txt +="				(\n"
		txt +="					glueMaterial ui:sel_shader_type type:#string default:\"\"\n"
		txt +="					glueMat_path type:#string \n"
		txt +="				)\n"
		txt +="				rollout glueShaderType \"glueShaderType\" width:162 height:300\n"
		txt +="				(\n"
		txt +="					button sel_shader_type \"ѡ�� Glue ��������\" pos:[7,6] width:116 height:21 \n"
		txt +="					label mat_name_lbl2 \"\" pos:[169,4] width:94 height:23                       \n"
		txt +="					on sel_shader_type pressed  do                                              \n"
		txt +="					(                                                                           \n"
		txt +="						thePath = getOpenFileName()                                             \n"
		txt +="				        if thePath == undefined do      \n"
		txt +="				        (                               \n"
		txt +="				        	return False               \n"
		txt +="				        )                               \n"
		txt +="						glueMat_path = thePath                                                  \n"
		txt +="					)                                                                           \n"
		txt +="				)                                                                               \n"
		txt +="			)                                                                                   \n"
		txt +="			custAttributes.add actmm glue_ShaderType                                            \n"
		txt +="			)                                                                                        \n"
		txt +="			)\n"
		txt +="			)                                                                                            \n"
		txt +="		)\n"
		txt +=")                                                                                             \n"
		callbacks.addscript #mtlRefAdded txt id:#AssignGlueMat persistent:false
	  )
	  else
	  (
		callbacks.removescripts id:#AssignGlueMat
	  )
	)

	fn clear_attr obj = 
	(
		get_attr_num = custAttributes.count obj
		if get_attr_num > 0 do
		(
			for i=1 to get_attr_num do
			(
				attr = custAttributes.get obj i
				custAttributes.delete obj i
			)
		)
	)
	-- clear_attr $.mat


on execute do 
(
	matEditor.open()
	add_curntMat_attr()
	add_glue_attr()
)


----------------------------------------------------------------------------- mat attribute end
)
if menuMan.registerMenuContext 0x7654ab68 then
(
	clearlistener()
	local mainMenuBar = menuMan.getMainMenuBar()
	local glueMenu = menuMan.createMenu "Glue"
	local subMenuItem = menuMan.createSubMenuItem "Glue" glueMenu
	
	--------material
	local matListItem = menuMan.createActionItem "materialList" "Superpolo"
	glueMenu.addItem matListItem -1
	
	--------render
	local max_gmeditorItem = menuMan.createActionItem "max_gmeditor" "Superpolo"
	glueMenu.addItem max_gmeditorItem -1
	
	local subMenuIndex = mainMenuBar.numItems() - 1
	mainMenuBar.addItem subMenuItem subMenuIndex
	
	menuMan.updateMenuBar()
)