CoreGui = game:GetService("CoreGui")

-- No iniciar una segunda copia si la anterior sigue activa.
if CoreGui:FindFirstChild("FTFXEXECUTED") then
	return
end

ContextActionService = game:GetService("ContextActionService")
if not game:IsLoaded() then
	game.Loaded:Wait()
end

Players = game:GetService("Players")
RunService = game:GetService("RunService")
Lighting = game:GetService("Lighting")
ReplicatedStorage = game:GetService("ReplicatedStorage")
UserInputService = game:GetService("UserInputService")

-- Carga protegida: un fallo de red, compilacion o ejecucion no deja un marcador
-- bloqueando futuros intentos. Se conserva Obsidian y sus dos addons.
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"

local function LoadObsidianModule(relativePath, moduleName)
	local success, result = pcall(function()
		local source = game:HttpGet(repo .. relativePath)
		if type(source) ~= "string" or #source == 0 then
			error("respuesta vacia al descargar " .. moduleName)
		end

		if type(loadstring) ~= "function" then
			error("este executor no ofrece loadstring")
		end

		local chunk, compileError = loadstring(source)
		if type(chunk) ~= "function" then
			error("no se pudo compilar " .. moduleName .. ": " .. tostring(compileError))
		end

		local ran, module = pcall(chunk)
		if not ran then
			error("error ejecutando " .. moduleName .. ": " .. tostring(module))
		end
		if type(module) ~= "table" then
			error(moduleName .. " no devolvio una tabla valida")
		end
		return module
	end)

	if not success then
		warn("[FTFX] No se pudo cargar " .. moduleName .. ": " .. tostring(result))
		return nil
	end
	return result
end

Library = LoadObsidianModule("Library.lua", "Obsidian Library")
if not Library or type(Library.CreateWindow) ~= "function" or type(Library.Options) ~= "table" then
	warn("[FTFX] Inicio cancelado: Obsidian Library no esta disponible o es incompatible.")
	return
end

ThemeManager = LoadObsidianModule("addons/ThemeManager.lua", "ThemeManager")
if not ThemeManager
	or type(ThemeManager.SetLibrary) ~= "function"
	or type(ThemeManager.SetFolder) ~= "function"
	or type(ThemeManager.ApplyToTab) ~= "function"
then
	warn("[FTFX] Inicio cancelado: ThemeManager no esta disponible o es incompatible.")
	return
end

SaveManager = LoadObsidianModule("addons/SaveManager.lua", "SaveManager")
if not SaveManager
	or type(SaveManager.SetLibrary) ~= "function"
	or type(SaveManager.SetFolder) ~= "function"
	or type(SaveManager.LoadAutoloadConfig) ~= "function"
then
	warn("[FTFX] Inicio cancelado: SaveManager no esta disponible o es incompatible.")
	return
end

Options = Library.Options

player = Players.LocalPlayer
playergui = player.PlayerGui
map = ReplicatedStorage:WaitForChild("CurrentMap")

icon = "82103784428336"
theicon = icon
scriptname = "Christmas 2026"

Window = Library:CreateWindow({
    Title = scriptname,
    Footer = "Version X",
    NotifySide = "Right",
    MobileButtonsSide = "Left",
    Icon = theicon,

})

-- El marcador se crea despues de cargar las tres librerias y crear la ventana.
-- Si falla la descarga/compilacion de una dependencia, el siguiente intento no queda bloqueado.
local executionMarker = Instance.new("BoolValue")
executionMarker.Name = "FTFXEXECUTED"
executionMarker.Value = true
executionMarker.Parent = CoreGui

pcall(function()
	Library:OnUnload(function()
		if executionMarker and executionMarker.Parent then
			executionMarker:Destroy()
		end
	end)
end)

-- Helper: hace arrastrable cualquier GuiObject (mouse y touch).
-- Devuelve una tabla con .Moved (true si se arrastro, para ignorar el click).
function DragGui(gui)
	local state = { Moved = false }
	local stopPrev = nil

	gui.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if stopPrev then stopPrev() end
			state.Moved = false
			local dragStart = input.Position
			local startPos = gui.Position
			local moveConn, endConn

			local function stop()
				if moveConn then moveConn:Disconnect(); moveConn = nil end
				if endConn then endConn:Disconnect(); endConn = nil end
				if stopPrev == stop then stopPrev = nil end
			end
			stopPrev = stop

			-- Solo escucha el movimiento mientras el dedo/mouse esta presionado
			moveConn = UserInputService.InputChanged:Connect(function(i)
				if i ~= input and i.UserInputType ~= Enum.UserInputType.MouseMovement then return end
				local delta = i.Position - dragStart
				if not state.Moved and delta.Magnitude > 6 then
					state.Moved = true
				end
				if state.Moved then
					gui.Position = UDim2.new(
						startPos.X.Scale, startPos.X.Offset + delta.X,
						startPos.Y.Scale, startPos.Y.Offset + delta.Y
					)
				end
			end)
			endConn = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					stop()
				end
			end)
		end
	end)

	return state
end

Tabs = {
	["Visual"] = Window:AddTab({
		Name = "Visual",
		Icon = "wallpaper",
	}),
	["Gadgets"] = Window:AddTab({
		Name = "Gadgets",
		Icon = "cpu",
	}),

	["Danger Settings"] = Window:AddTab({
		Name = "Bowser Settings",
		Icon = "skull",
	}),

	["Esp Customization"] = Window:AddTab({
		Name = "Esp Customization",
		Icon = "palette",
	}),
	["Gadget Customization"] = Window:AddTab({
		Name = "Gadget Customization",
		Icon = "palette",
	}),
	["General Customization"] = Window:AddTab({
		Name = "General Customization",
		Icon = "palette",
	}),
	["Sound Customization"] = Window:AddTab({
		Name = "Sound Customization",
		Icon = "volume-2",
	}),
	["Crosshair"] = Window:AddTab({
		Name = "Misc",
		Icon = "folder",
	}),
	["UI Settings"] = Window:AddTab({
		Name = "UI Settings",
		Icon = "settings",
	}),
}

TabBoxes = {}

TabBoxes.Visual = {}
TabBoxes.Visual.Left = Tabs.Visual:AddLeftTabbox("Other Stuff")
TabBoxes.Visual.Right = Tabs.Visual:AddRightTabbox("Player ESP")

TabBoxes.Gadgets = {}
TabBoxes.Gadgets.Left = Tabs.Gadgets:AddLeftTabbox("Timers")
TabBoxes.Gadgets.Right = Tabs.Gadgets:AddRightTabbox("Progress Bars")

TabBoxes.EspCustomization = {}
TabBoxes.EspCustomization.Left = Tabs["Esp Customization"]:AddLeftTabbox("Player Esp")
TabBoxes.EspCustomization.Right = Tabs["Esp Customization"]:AddRightTabbox("Other")

TabBoxes.GadgetCustomization = {}
TabBoxes.GadgetCustomization.PcProgress = Tabs["Gadget Customization"]:AddLeftTabbox("PC Progress")
TabBoxes.GadgetCustomization.ExitProgress = Tabs["Gadget Customization"]:AddLeftTabbox("Exit Progress")
TabBoxes.GadgetCustomization.DoorProgress = Tabs["Gadget Customization"]:AddLeftTabbox("Door Progress")
TabBoxes.GadgetCustomization.GetupTimer = Tabs["Gadget Customization"]:AddRightTabbox("Getup Timer")
TabBoxes.GadgetCustomization.RunnerTimer = Tabs["Gadget Customization"]:AddRightTabbox("Runner Timer")
TabBoxes.GadgetCustomization.HeadstartTracker = Tabs["Gadget Customization"]:AddRightTabbox("HeadstartTracker")

GadgetCustomizationTabBox = Tabs["Gadget Customization"]:AddLeftTabbox("Walkspeed")
WalkspeedCustomization = GadgetCustomizationTabBox:AddTab("Walkspeed Detector")

DangerSettingsTabBox = Tabs["Danger Settings"]:AddLeftTabbox("Speed Settings")

Groupboxes = {}

Groupboxes.Visual = {}
Groupboxes.Visual.LeftGroupBox = TabBoxes.Visual.Left:AddTab("Other Esp")
Groupboxes.Visual.RightGroupBox = TabBoxes.Visual.Right:AddTab("Player ESP")

Groupboxes.Gadgets = {}
Groupboxes.Gadgets.Left = TabBoxes.Gadgets.Left:AddTab("Progress things")
Groupboxes.Gadgets.Right = TabBoxes.Gadgets.Right:AddTab("Timers")
Groupboxes.Gadgets.OtherGadgets = TabBoxes.Gadgets.Right:AddTab("Other Gadgets")

Groupboxes.EspCustomization = {}
Groupboxes.EspCustomization.PlayerEsp = TabBoxes.EspCustomization.Left:AddTab("Player")
Groupboxes.EspCustomization.Tracers = TabBoxes.EspCustomization.Left:AddTab("Tracers")
Groupboxes.EspCustomization.Skeleton = TabBoxes.EspCustomization.Left:AddTab("Skeleton")

Groupboxes.EspCustomization.PcAndTube = TabBoxes.EspCustomization.Right:AddTab("PC/Tube")
Groupboxes.EspCustomization.DoorEsp = TabBoxes.EspCustomization.Right:AddTab("Door")

Groupboxes.GadgetCustomization = {}
Groupboxes.GadgetCustomization.PcProgress = TabBoxes.GadgetCustomization.PcProgress:AddTab("PC Progress")
Groupboxes.GadgetCustomization.ExitProgress = TabBoxes.GadgetCustomization.ExitProgress:AddTab("Exit Progress")
Groupboxes.GadgetCustomization.DoorProgress = TabBoxes.GadgetCustomization.DoorProgress:AddTab("Door Progress")
Groupboxes.GadgetCustomization.GetupTimer = TabBoxes.GadgetCustomization.GetupTimer:AddTab("Getup Timer")
Groupboxes.GadgetCustomization.RunnerTimer = TabBoxes.GadgetCustomization.RunnerTimer:AddTab("Runner Timer")
Groupboxes.GadgetCustomization.HeadstartTracker =
	TabBoxes.GadgetCustomization.HeadstartTracker:AddTab("Headstart Tracker")

local Settings = {
	EspSettings = {
		PlayerEsp = {
			Enabled = false,
			UseSkeletonEsp = false,
			UseCloneEsp = false,
			SurvivorFillColor = Color3.fromRGB(0, 255, 0),
			BeastFillColor = Color3.fromRGB(255, 0, 0),
			SurvivorOutlineColor = Color3.fromRGB(0, 0, 0),
			BeastOutlineColor = Color3.fromRGB(0, 0, 0),
			BeastOutlineTransparancy = 0,
			SurvivorOutlineTransparancy = 0,
			SurvivorFillTransparancy = 0.5,
			BeastFillTransparancy = 0.5,
			TracerSettings = {
				Enabled = false,
				Thickness = 1.1,
				Color = Color3.new(0, 1, 0),
				FromBottom = true,
				Transparancy = 0,
			},
			SkeletonSettings = {
				Color = Color3.new(0, 1, 0),
				Thickness = 1.1,
				Transparency = 1,
			},
		},
		PcEsp = {
			Enabled = false,
			FillColor = Color3.fromRGB(0, 150, 255),
			DoneFillColor = Color3.fromRGB(0, 255, 0),
			OutlineColor = Color3.fromRGB(0, 0, 0),
			OutlineTransparency = 0.25,
			FillTransparency = 0.5,
		},
		TubeEsp = {
			Enabled = false,
			FillColor = Color3.fromRGB(13, 105, 172),
			OutlineColor = Color3.fromRGB(0, 0, 0),
			OutlineTransparency = 0.25,
			FillTransparency = 0.5,
		},
		ExitEsp = {
			Enabled = false,
			FillColor = Color3.fromRGB(85, 255, 127),
			OutlineColor = Color3.fromRGB(0, 0, 0),
			OutlineTransparency = 0.25,
			FillTransparency = 0.5,
		},
		DoorEsp = {
			Enabled = false,
			OpenColor = Color3.fromRGB(0, 255, 0),
			ClosedColor = Color3.fromRGB(255, 0, 0),
			OpenOutlineColor = Color3.fromRGB(0, 0, 0),
			ClosedOutlineColor = Color3.fromRGB(0, 0, 0),
			OutlineTransparency = 0.25,
			ClosedFillTransparency = 0.5,
			OpenFillTransparency = 0.5,
		},
	},
	GadgetSettings = {
		ProgressSettings = {
			PcProgress = {
				Enabled = false,
				TextColor = Color3.fromRGB(255, 255, 255),
				ProgressFill = Color3.fromRGB(255, 255, 255),
				BackgroundColor = Color3.fromRGB(32, 32, 32),
				ProgressTransparancy = 0.1,
				BackgroundTransparancy = 0.4,
				DisplaySeconds = false,
			},
			ExitProgress = {
				Enabled = false,
				TextColor = Color3.fromRGB(85, 255, 127),
				ProgressFill = Color3.fromRGB(85, 255, 127),
				BackgroundColor = Color3.fromRGB(32, 32, 32),
				ProgressTransparancy = 0.1,
				BackgroundTransparancy = 0.4,
				DisplaySeconds = false,
				DisplayOpener = false,
				OpenerTextColor = Color3.fromRGB(255, 255, 0),
			},
			DoorProgress = {
				Enabled = false,
				TextColor = Color3.fromRGB(133, 88, 0),
				ProgressFill = Color3.fromRGB(133, 88, 0),
				BackgroundColor = Color3.fromRGB(32, 32, 32),
				ProgressTransparancy = 0.1,
				BackgroundTransparancy = 0.4,
				DisplaySeconds = false,
				DisplayOpener = false,
				OpenerTextColor = Color3.fromRGB(255, 255, 0),
			},
			GetupTimer = {
				Enabled = false,
				NotHitColor = Color3.fromRGB(255, 0, 0),
				HitColor = Color3.fromRGB(34, 255, 0),
				WhenToHit = 0.5,
				SmoothMode = true,
				-- 20 ms por defecto (50 actualizaciones/s): se ve igual de fluido y cuesta menos FPS que 14 ms.
				UpdateRate = 0.02,
				SoundEnabled = false,
				SoundSecondsLeft = 6,
			},
			RunnerTimer = {
				Enabled = false,
				DisplaySeconds = false,
				TextColor = Color3.fromRGB(255, 255, 255),
			},
		},
		OtherGadgets = {
			HideBlack = false,
			NeverFail = false,
			WalkspeedDetector = {
				Enabled = false,
				TextColor = Color3.fromRGB(255, 255, 255),
				StrokeColor = Color3.fromRGB(0, 0, 0),
				TextTransparency = 0,
				StrokeTransparency = 0,
			},
			HeadstartTracker = {
				Enabled = false,
				TextColor = Color3.fromRGB(255, 255, 255),
				StrokeColor = Color3.fromRGB(0, 0, 0),
				StrokeTransparancy = 0,
				TextTransparancy = 0,
				TrackerConnection = nil,
			},
		},
	},
}

SpeedSettings = {
	Enabled = false,

	SurvivorBoost = 1,
	BeastBoost = 1,
	RunnerBoost = 2,
	FatigueBoost = 1,
	CrawlBoost = 2,

	JumpPowerEnabled = false, -- boton Activar/Desactivar de Jump Power Settings
	LastAppliedJP = nil,
	SurvivorJumpPower = 36,
	BeastJumpPower = 36,

	Connection = nil,

	UseFatigueCheats = false,
	FatigueDelay = 0,
	FatigueDuration = 0.8,
}
FogSettings = {
	Enabled = false,
	Conns = {},
}

-- Boost Game manda sobre niebla / sombras / efectos: No Fog, Black Fog y Shaders lo consultan
-- para no deshacer lo que Boost Game hizo (y Boost Game funciona aunque ellos esten activos).
function IsBoosting()
	return BoostGame ~= nil and BoostGame.Saved ~= nil
end

-- Densidad REAL de una Atmosphere (si Boost Game la puso en 0, devuelve la que tenia antes)
function RealAtmDensity(atm)
	local bs = IsBoosting() and BoostGame.Saved
	local e = bs and bs.Effects[atm]
	if e and e[1] == "Density" then
		return e[2]
	end
	return atm.Density
end

-- Cuando otro modulo restaura la niebla, Boost Game la vuelve a dejar en 0
function BoostKeepAtmosphere()
	if not IsBoosting() then
		return
	end
	for _, c in ipairs(Lighting:GetChildren()) do
		if c:IsA("Atmosphere") and c.Density ~= 0 then
			c.Density = 0
		end
	end
end

WallhopSettings = {
	Enabled = false,
	SelectionBoxes = {},
}

BarrierSettings = {
	Enabled = false,
	OriginalTransparencies = {},
}

CrosshairSettings = {
	Enabled = false,
	Type = "Normal cursor",
	Color = Color3.fromRGB(255, 255, 255), -- blanco = la imagen se ve con sus colores originales
	UseColor = false, -- si esta apagado, el cursor usa sus colores originales
	Order = { "Normal cursor", "Danger cursor" },
	Types = {
		-- Slider 1-100 se convierte a pixeles reales entre Min y Max
		["Normal cursor"] = { DecalId = 77877446296275, Min = 16, Max = 130, Slider = 100, OffsetX = 0, OffsetY = -6 },
		["Danger cursor"] = { DecalId = 83818771234657, Min = 12, Max = 170, Slider = 50, OffsetX = 0, OffsetY = 0 },
	},
}
BushSettings = {
	Enabled = false,
	Cached = {},
}

ShadowSettings = {
	Enabled = false,
	OriginalState = true,
}

KillAuraSettings = {
	Enabled = false,
	MaxDistance = 30,
	Connection = nil,
	LastHitTimes = {},
	HitCooldown = 0.5,
}

RopeHelperSettings = {
	Enabled = false,
	AutoRopeOnHit = false,
	ClickToRope = false,
	MaxDistance = 30,
	RandomizePart = false,
	SelectedPart = "Torso",
}
PlayerConnections = {
	EspConnections = {},
	PcEsp = {},
	TubeEsp = {},
	ExitEsp = {},
	DoorEsp = {},
}

FlopSettings = {
	Enabled = false,
	Delay = 1.5,
	XMultiplier = 1,
	YMultiplier = 0,
	ZMultiplier = 1,
	LastFlopTime = 0,
	FlopConnection = nil,
}

SkeletonUIs = {}
SkeletonConnections = {}

TracerLines = {}
TracerConnections = {}

previousValues = {}

HitPlayers = {}
GetupConnections = {}
GetupUis = {}
c = 28

computers = {}
exits = {}
doors = {}

objectProgress = {
	computers = {},
	doors = {},
	exits = {},
}

runnerStates = {}

WalkspeedUIs = {}

lastUpdate = 0
UPDATE_INTERVAL = 1 / 30

RankData = {
	["VIP"] = { Color = "#CC0000", Icon = "rbxassetid://1188562340" },
	["LEAD DEV"] = { Color = "#00FF33", Icon = "rbxassetid://18937953345" },
	["MAN"] = { Color = "#ff34c4", Icon = "rbxassetid://131476591459702" },
	["DEV"] = { Color = "#1E5CBA", Icon = "rbxassetid://18940006678" },
	["QA"] = { Color = "#F85E5E", Icon = "rbxassetid://18940008283" },
	["MOD"] = { Color = "#bc3fff", Icon = "rbxassetid://105155010224102" },
	["CON"] = { Color = "#1ABC9C", Icon = "rbxassetid://18940005647" },
	["Cruzy"] = { Color = "#FF9900", Icon = "rbxassetid://136173586615424" },
	["Kiyam"] = { Color = "#00D5FF", Icon = "rbxassetid://135601954048658" },
	["Relative"] = { Color = "#FF5E00", Icon = "rbxassetid://72807915177915" },
	["Corksuable"] = { Color = "#A8FF3D", Icon = "rbxassetid://135738630748193" },
	["Yoshi"] = { Color = "#FFD700", Icon = "rbxassetid://93649728520449" },
	["Bowser JR"] = { Color = "#FF8C00", Icon = "rbxassetid://103134906031517" },
	["Danger"] = { Color = "#FF2D2D", Icon = "rbxassetid://132454521998375" },
	["Brokensfr"] = { Color = "#B84DFF", Icon = "rbxassetid://70443396654057" },
	["Noschillies"] = { Color = "#3DDC84", Icon = "rbxassetid://138013853842250" },
	["Pilot"] = { Color = "#4DA6FF", Icon = "rbxassetid://97732004736329" },
	["Rashad"] = { Color = "#FF6EC7", Icon = "rbxassetid://104136290091936" },
}

RankList = { "None", "VIP", "LEAD DEV", "MAN", "DEV", "QA", "MOD", "CON" }
-- Solo para "Your Rank Tag": los 3 nuevos aparecen justo debajo de None
MyRankList = { "None", "Cruzy", "Kiyam", "Relative", "Corksuable", "Yoshi", "Bowser JR", "Danger", "Brokensfr", "Noschillies", "Pilot", "Rashad", "VIP", "LEAD DEV", "MAN", "DEV", "QA", "MOD", "CON" }

RainbowEspState = {
	Enabled = false,
	Hue = 0,
	Speed = 0.1,
	Connection = nil,
}

FontSettings = {
	Enabled = false,
	SelectedFont = Enum.Font.SourceSans,
	Connections = {},
}

BlackFogGammaSettings = {
	Enabled = false,
	FogAuto = false, -- Black Fog puso el Color Correction (gamma 1.11) por su cuenta
	GammaValue = 1, -- valor por defecto (neutro, sin efecto)
	OriginalBrightness = nil,
	ColorCorrection = nil,
}

-- ============================================================
-- QUITAR PASOS Y SALTOS PROPIOS (solo eventos, sin loops = sin lag)
-- ============================================================
OwnStepJumpMute = {
	Enabled = false,
	Muted = setmetatable({}, { __mode = "k" }), -- sound -> volumen original
	Conns = {},
	Names = { Running = true, Jumping = true },
}

function OwnStepJumpMute_MuteSound(sound)
	if not sound:IsA("Sound") or not OwnStepJumpMute.Names[sound.Name] then
		return
	end
	if OwnStepJumpMute.Muted[sound] == nil then
		OwnStepJumpMute.Muted[sound] = sound.Volume
		table.insert(OwnStepJumpMute.Conns, sound:GetPropertyChangedSignal("Volume"):Connect(function()
			if OwnStepJumpMute.Enabled and sound.Volume ~= 0 then
				sound.Volume = 0
			end
		end))
	end
	sound.Volume = 0
end

function OwnStepJumpMute_HookCharacter(character)
	task.spawn(function()
		local hrp = character:WaitForChild("HumanoidRootPart", 5)
		if not hrp or not OwnStepJumpMute.Enabled then
			return
		end
		for _, child in ipairs(hrp:GetChildren()) do
			OwnStepJumpMute_MuteSound(child)
		end
		table.insert(OwnStepJumpMute.Conns, hrp.ChildAdded:Connect(function(child)
			if OwnStepJumpMute.Enabled then
				OwnStepJumpMute_MuteSound(child)
			end
		end))
	end)
end

function StartOwnStepJumpMute()
	OwnStepJumpMute.Enabled = true
	if player.Character then
		OwnStepJumpMute_HookCharacter(player.Character)
	end
	table.insert(OwnStepJumpMute.Conns, player.CharacterAdded:Connect(function(character)
		OwnStepJumpMute_HookCharacter(character)
	end))
end

function StopOwnStepJumpMute()
	OwnStepJumpMute.Enabled = false
	for _, conn in ipairs(OwnStepJumpMute.Conns) do
		conn:Disconnect()
	end
	OwnStepJumpMute.Conns = {}
	for sound, volume in pairs(OwnStepJumpMute.Muted) do
		if sound and sound.Parent then
			sound.Volume = volume
		end
		OwnStepJumpMute.Muted[sound] = nil
	end
end

ShaderSettings = {
	Enabled = false,
}

-- Preset "Default" activo (el dropdown empieza en Default)
ShaderIsDefault = true
-- Niebla propia del juego (la ultima que el juego puso, antes de que los shaders la quitaran)
ShaderGameFog = {}
ShaderFogReleased = false

do
	local nfRemote, nfAcc, nfConn = nil, 0, nil
	-- Solo existe la conexion mientras Never Fail esta prendido (apagado = 0 codigo corriendo)
	function SetNeverFail(on)
		if nfConn then
			nfConn:Disconnect()
			nfConn = nil
		end
		if not on then
			return
		end
		nfAcc = 0
		nfConn = RunService.Heartbeat:Connect(function(dt)
			nfAcc = nfAcc + dt
			if nfAcc < 0.05 then
				return
			end
			nfAcc = 0
			if not nfRemote or not nfRemote.Parent then
				nfRemote = ReplicatedStorage:FindFirstChild("RemoteEvent")
				if not nfRemote then
					return
				end
			end
			nfRemote:FireServer("SetPlayerMinigameResult", true)
		end)
	end
end

local shaderlight = {
	["yfbghj"] = Lighting.Ambient,
	["tgvbyd"] = Lighting.ClockTime,
	["ghuybhuyhj"] = Lighting.GeographicLatitude,
	["khnbfth"] = Lighting.Brightness,
	["hgyghkg"] = Lighting.ColorShift_Bottom,
	["yfbhjku"] = Lighting.ColorShift_Top,
	["ygyyfgvhbjytrt"] = Lighting.EnvironmentDiffuseScale,
	["sdfcddc"] = Lighting.EnvironmentSpecularScale,
	["hgnujuu7thgr"] = Lighting.GlobalShadows,
	["hyhnngtf"] = Lighting.OutdoorAmbient,
	["hdfr7thgr"] = Lighting.ExposureCompensation,
	["fhnchvhfjsd"] = 0,
	["ugtbbjhygt"] = 0,
	["tfbghuugbnjhg"] = 0,
	["fvrtccvghghj"] = Color3.fromRGB(255, 255, 255),
	["jnfdhbnfcvh"] = 0.4,
	["fvtyghj"] = 24,
	["ygbhnj"] = 0.95,
	["njnfg"] = 0,
	["jdfkd"] = 0.1,
	["fvgsdfg"] = 50,
	["sdkvkflv"] = 10,
	["hbjhd"] = 0.75,
	["gyhgtg"] = 0,
	["ygbhggv"] = 0,
	["jghbjhgyfd"] = Color3.fromRGB(255, 255, 255),
	["shdbsnjfc"] = 0,
	["skdjfkdm"] = 0,
	["sjdjncdjf"] = Color3.fromRGB(199, 199, 199),
	["efjdjfk"] = Color3.fromRGB(106, 112, 125),
	["sejfd"] = 0,
	["jddfjsd"] = 0,
}

backupLighting = {
	["ClockTime"] = Lighting.ClockTime,
	["Ambient"] = Lighting.Ambient,
	["Brightness"] = Lighting.Brightness,
	["ColorShift_Bottom"] = Lighting.ColorShift_Bottom,
	["ColorShift_Top"] = Lighting.ColorShift_Top,
	["EnvironmentDiffuseScale"] = Lighting.EnvironmentDiffuseScale,
	["EnvironmentSpecularScale"] = Lighting.EnvironmentSpecularScale,
	["GlobalShadows"] = Lighting.GlobalShadows,
	["OutdoorAmbient"] = Lighting.OutdoorAmbient,
	["ExposureCompensation"] = Lighting.ExposureCompensation,
	["FogEnd"] = Lighting.FogEnd,
	["FogColor"] = Lighting.FogColor,
	["FogStart"] = Lighting.FogStart,
	["GeographicLatitude"] = Lighting.GeographicLatitude,
	["Technology"] = Lighting.Technology,
}

shaderWL = {
	["cor"] = false,
	["bl"] = false,
	["tech"] = "ShadowMap",
}

function createR6Dummy(cf)
	local m = Instance.new("Model")
	m.Name = "R6Dummy"
	m.Parent = workspace

	local function p(n, s, c)
		local x = Instance.new("Part")
		x.Name = n
		x.Size = s
		x.CFrame = c
		x.Anchored = false
		x.CanCollide = false
		x.TopSurface = 0
		x.BottomSurface = 0
		x.Parent = m
		return x
	end

	local hrp = p("HumanoidRootPart", Vector3.new(2, 2, 1), cf)
	hrp.Transparency = 1
	local torso = p("Torso", Vector3.new(2, 2, 1), cf)
	local head = p("Head", Vector3.new(2, 1, 1), cf * CFrame.new(0, 1.5, 0))
	local la = p("Left Arm", Vector3.new(1, 2, 1), cf * CFrame.new(-1.5, 0, 0))
	local ra = p("Right Arm", Vector3.new(1, 2, 1), cf * CFrame.new(1.5, 0, 0))
	local ll = p("Left Leg", Vector3.new(1, 2, 1), cf * CFrame.new(-0.5, -2, 0))
	local rl = p("Right Leg", Vector3.new(1, 2, 1), cf * CFrame.new(0.5, -2, 0))

	local function m6(n, a, b, c0, c1)
		local j = Instance.new("Motor6D")
		j.Name = n
		j.Part0 = a
		j.Part1 = b
		j.C0 = c0
		j.C1 = c1
		j.Parent = a
	end

	m6("RootJoint", hrp, torso, CFrame.new(), CFrame.new())
	m6("Neck", torso, head, CFrame.new(0, 1, 0), CFrame.new(0, -0.5, 0))
	m6("Left Shoulder", torso, la, CFrame.new(-1, 0.5, 0), CFrame.new(0.5, 0.5, 0))
	m6("Right Shoulder", torso, ra, CFrame.new(1, 0.5, 0), CFrame.new(-0.5, 0.5, 0))
	m6("Left Hip", torso, ll, CFrame.new(-0.5, -1, 0), CFrame.new(0, 1, 0))
	m6("Right Hip", torso, rl, CFrame.new(0.5, -1, 0), CFrame.new(0, 1, 0))

	local d = Instance.new("Decal", head)
	d.Texture = "rbxasset://textures/face.png"
	d.Name = "face"

	local h = Instance.new("Humanoid")
	h.RigType = Enum.HumanoidRigType.R6
	h.Parent = m

	return m
end

function applyavatar(targetplayername, idorusername)
	local isid = typeof(idorusername) == "number"
	local description

	if isid then
		local success, desc = pcall(function()
			return Players:GetHumanoidDescriptionFromUserId(idorusername)
		end)
		if not success or not desc then
			Library:Notify("The player you're trying to change your avatar into doesn't exist!")
			return
		end
		description = desc
	else
		local success, actualuserid = pcall(function()
			return Players:GetUserIdFromNameAsync(idorusername)
		end)
		if not success or not actualuserid then
			Library:Notify("The player youre trying to change your avatar into doesnt exist!")
			return
		end
		local success2, desc = pcall(function()
			return Players:GetHumanoidDescriptionFromUserId(actualuserid)
		end)
		if not success2 or not desc then
			Library:Notify("Failed to get humanoid description!")
			return
		end
		description = desc
	end

	local doesplayerexist = Players:FindFirstChild(targetplayername)
	if not doesplayerexist then
		Library:Notify("Youre trying to change the avatar of a player thats not in the game!")
		return
	end

	local thechar = doesplayerexist.Character
	if not thechar then
		Library:Notify("The player youre trying to change the avatar of has no character!")
		return
	end

	local thehumanoid = thechar:FindFirstChild("Humanoid")
	if not thehumanoid then
		Library:Notify("Character has no humanoid!")
		return
	end

	for _, part in ipairs(thechar:GetChildren()) do
		if
			part:IsA("Accessory")
			or part:IsA("Hat")
			or part:IsA("Shirt")
			or part:IsA("Pants")
			or part:IsA("ShirtGraphic")
			or part:IsA("CharacterMesh")
			or part:IsA("BodyColors")
		then
			part:Destroy()
		end
	end

	local headpart = thechar:FindFirstChild("Head")
	if headpart then
		for _, child in ipairs(headpart:GetChildren()) do
			if child:IsA("Decal") or child:IsA("Texture") then
				child:Destroy()
			end
		end
	end

	local burnerrig = createR6Dummy(CFrame.new(10000, 10000, 10000))
	local burnerhumanoid = burnerrig:FindFirstChild("Humanoid")
	burnerhumanoid:ApplyDescription(description)
	task.wait(3)

	for _, part in ipairs(burnerrig:GetChildren()) do
		if part:IsA("Accessory") or part:IsA("Hat") then
			local cloned = part:Clone()
			cloned.Parent = thechar

			local handle = cloned:FindFirstChild("Handle")
			if handle then
				local attached = false
				local handleAttachment = handle:FindFirstChildOfClass("Attachment")
				if handleAttachment then
					local attachmentName = handleAttachment.Name
					for _, bodyPart in ipairs(thechar:GetChildren()) do
						if bodyPart:IsA("BasePart") then
							local matchingAttachment = bodyPart:FindFirstChild(attachmentName)
							if matchingAttachment and matchingAttachment:IsA("Attachment") then
								local weld = handle:FindFirstChild("AccessoryWeld")
								if not weld then
									weld = Instance.new("Weld")
									weld.Name = "AccessoryWeld"
									weld.Parent = handle
								end
								weld.Part0 = handle
								weld.Part1 = bodyPart
								weld.C0 = handleAttachment.CFrame
								weld.C1 = matchingAttachment.CFrame
								attached = true
								break
							end
						end
					end
				end
				if not attached and headpart then
					local weld = handle:FindFirstChild("AccessoryWeld")
					if not weld then
						weld = Instance.new("Weld")
						weld.Name = "AccessoryWeld"
						weld.Parent = handle
					end
					weld.Part0 = handle
					weld.Part1 = headpart
					weld.C0 = CFrame.new()
					weld.C1 = CFrame.new(0, headpart.Size.Y / 2, 0)
				end
			end
		elseif
			part:IsA("Shirt")
			or part:IsA("Pants")
			or part:IsA("ShirtGraphic")
			or part:IsA("CharacterMesh")
			or part:IsA("BodyColors")
		then
			part:Clone().Parent = thechar
		end
	end

	local burnerhead = burnerrig:FindFirstChild("Head")
	if burnerhead and headpart then
		local burnerMesh = burnerhead:FindFirstChildOfClass("SpecialMesh")
		local targetMesh = headpart:FindFirstChildOfClass("SpecialMesh")
		if burnerMesh then
			if targetMesh then
				pcall(function()
					targetMesh.MeshType = burnerMesh.MeshType
				end)
				pcall(function()
					targetMesh.MeshId = burnerMesh.MeshId
				end)
				pcall(function()
					targetMesh.TextureId = burnerMesh.TextureId
				end)
				pcall(function()
					targetMesh.Scale = burnerMesh.Scale
				end)
				pcall(function()
					targetMesh.Offset = burnerMesh.Offset
				end)
				pcall(function()
					targetMesh.VertexColor = burnerMesh.VertexColor
				end)
			else
				burnerMesh:Clone().Parent = headpart
			end
		end

		local foundFace = false
		for _, child in ipairs(burnerhead:GetChildren()) do
			if child:IsA("Decal") or child:IsA("Texture") then
				child:Clone().Parent = headpart
				foundFace = true
			end
		end

		if not foundFace and description.Face and description.Face ~= 0 then
			local faceDecal = Instance.new("Decal")
			faceDecal.Name = "face"
			faceDecal.Texture = "rbxassetid://" .. tostring(description.Face)
			faceDecal.Parent = headpart
		end
	end

	local r6ColorMap = {
		Head = description.HeadColor,
		Torso = description.TorsoColor,
		["Left Arm"] = description.LeftArmColor,
		["Right Arm"] = description.RightArmColor,
		["Left Leg"] = description.LeftLegColor,
		["Right Leg"] = description.RightLegColor,
	}
	for partName, color in pairs(r6ColorMap) do
		local targetPart = thechar:FindFirstChild(partName)
		if targetPart and targetPart:IsA("BasePart") and color then
			targetPart.Color = color
		end
	end

	local scaleNames = {
		"BodyDepthScale",
		"BodyHeightScale",
		"BodyWidthScale",
		"HeadScale",
		"BodyTypeScale",
		"BodyProportionScale",
	}
	for _, scaleName in ipairs(scaleNames) do
		local burnerScale = burnerhumanoid:FindFirstChild(scaleName)
		local targetScale = thehumanoid:FindFirstChild(scaleName)
		if burnerScale and targetScale and burnerScale:IsA("NumberValue") and targetScale:IsA("NumberValue") then
			targetScale.Value = burnerScale.Value
		elseif burnerScale and burnerScale:IsA("NumberValue") and not targetScale then
			local newScale = Instance.new("NumberValue")
			newScale.Name = scaleName
			newScale.Value = burnerScale.Value
			newScale.Parent = thehumanoid
		end
	end

	burnerrig:Destroy()
	Library:Notify("Avatar applied successfully!", 3)
end

function UpdateBlackFogGamma()
	if not BlackFogGammaSettings.Enabled or not BlackFogGammaSettings.ColorCorrection then
		return
	end

	local gamma = BlackFogGammaSettings.GammaValue
	local brightness = (gamma - 1) * 0.5
	BlackFogGammaSettings.ColorCorrection.Brightness = brightness
	-- Neutro en gamma = 1 (antes en 1 ya quedaba con contraste 0.2). En 1.11 da el mismo contraste (0.22) de antes.
	BlackFogGammaSettings.ColorCorrection.Contrast = (gamma - 1) * 2
	-- Siempre prendido mientras la opcion esta activa (Stop lo apaga)
	if not BlackFogGammaSettings.ColorCorrection.Enabled then
		BlackFogGammaSettings.ColorCorrection.Enabled = true
	end
end

function StartBlackFogGamma()
	if not BlackFogGammaSettings.ColorCorrection then
		BlackFogGammaSettings.ColorCorrection = Lighting:FindFirstChild("BlackFogGammaCorrection")
		if not BlackFogGammaSettings.ColorCorrection then
			BlackFogGammaSettings.ColorCorrection = Instance.new("ColorCorrectionEffect")
			BlackFogGammaSettings.ColorCorrection.Name = "BlackFogGammaCorrection"
			BlackFogGammaSettings.ColorCorrection.Parent = Lighting
		end
		BlackFogGammaSettings.OriginalBrightness = BlackFogGammaSettings.ColorCorrection.Brightness
	end
	UpdateBlackFogGamma()
end

function StopBlackFogGamma()
	if BlackFogGammaSettings.ColorCorrection then
		if BlackFogGammaSettings.OriginalBrightness then
			BlackFogGammaSettings.ColorCorrection.Brightness = BlackFogGammaSettings.OriginalBrightness
			BlackFogGammaSettings.ColorCorrection.Contrast = 0
			BlackFogGammaSettings.ColorCorrection.Enabled = false
		end
	end
end

-- Black Fog: si el Color Correction del gamma no existe lo crea y lo deja en gamma 1.11.
-- Si el usuario ya prendio "Enable Gamma Adjustment" manda su slider y esto no toca nada.
BLACKFOG_AUTO_GAMMA = 1.11

function BlackFogGamma_GetCC()
	local cc = BlackFogGammaSettings.ColorCorrection
	if cc and cc.Parent == Lighting then
		return cc
	end
	cc = Lighting:FindFirstChild("BlackFogGammaCorrection")
	if not cc then
		cc = Instance.new("ColorCorrectionEffect")
		cc.Name = "BlackFogGammaCorrection"
		cc.Parent = Lighting
	end
	BlackFogGammaSettings.ColorCorrection = cc
	BlackFogGammaSettings.OriginalBrightness = cc.Brightness
	return cc
end

function BlackFogGamma_Auto(on)
	if on then
		if BlackFogGammaSettings.Enabled then
			return
		end
		BlackFogGammaSettings.FogAuto = true
		local cc = BlackFogGamma_GetCC()
		local gamma = BLACKFOG_AUTO_GAMMA
		cc.Brightness = (gamma - 1) * 0.5
		cc.Contrast = (gamma - 1) * 2
		if not cc.Enabled then
			cc.Enabled = true
		end
	elseif BlackFogGammaSettings.FogAuto then
		BlackFogGammaSettings.FogAuto = false
		if not BlackFogGammaSettings.Enabled then
			StopBlackFogGamma()
		end
	end
end

function LoadShaderPresets()
	local presets = {
		["morning"] = {
			["yfbghj"] = Color3.fromRGB(138, 138, 138),
			["tgvbyd"] = 6.5,
			["ghuybhuyhj"] = 41.7,
			["khnbfth"] = 2,
			["hgyghkg"] = Color3.fromRGB(0, 0, 0),
			["yfbhjku"] = Color3.fromRGB(0, 0, 0),
			["ygyyfgvhbjytrt"] = 0.25,
			["sdfcddc"] = 0.25,
			["hgnujuu7thgr"] = true,
			["hyhnngtf"] = Color3.fromRGB(138, 138, 138),
			["hdfr7thgr"] = 0.2,
			["fhnchvhfjsd"] = 0.02,
			["ugtbbjhygt"] = 0.1,
			["tfbghuugbnjhg"] = -0.2,
			["fvrtccvghghj"] = Color3.fromRGB(255, 255, 255),
			["jnfdhbnfcvh"] = 0.8,
			["fvtyghj"] = 24,
			["ygbhnj"] = 0.8,
			["njnfg"] = 0,
			["jdfkd"] = 0.1,
			["fvgsdfg"] = 50,
			["sdkvkflv"] = 15,
			["hbjhd"] = 0.75,
			["gyhgtg"] = 0.4,
			["ygbhggv"] = 0.3,
			["jghbjhgyfd"] = Color3.fromRGB(255, 248, 231),
			["shdbsnjfc"] = 0.31,
			["skdjfkdm"] = 0.25,
			["sjdjncdjf"] = Color3.fromRGB(199, 199, 199),
			["efjdjfk"] = Color3.fromRGB(106, 112, 125),
			["sejfd"] = 0.1,
			["jddfjsd"] = 0,
		},
		["midday"] = {
			["yfbghj"] = Color3.fromRGB(138, 138, 138),
			["tgvbyd"] = 14,
			["ghuybhuyhj"] = 41.7,
			["khnbfth"] = 2,
			["hgyghkg"] = Color3.fromRGB(0, 0, 0),
			["yfbhjku"] = Color3.fromRGB(0, 0, 0),
			["ygyyfgvhbjytrt"] = 0.25,
			["sdfcddc"] = 0.25,
			["hgnujuu7thgr"] = true,
			["hyhnngtf"] = Color3.fromRGB(138, 138, 138),
			["hdfr7thgr"] = 0,
			["fhnchvhfjsd"] = 0,
			["ugtbbjhygt"] = 0.1,
			["tfbghuugbnjhg"] = 0,
			["fvrtccvghghj"] = Color3.fromRGB(255, 255, 255),
			["jnfdhbnfcvh"] = 1,
			["fvtyghj"] = 24,
			["ygbhnj"] = 0.95,
			["njnfg"] = 0,
			["jdfkd"] = 0.1,
			["fvgsdfg"] = 50,
			["sdkvkflv"] = 10,
			["hbjhd"] = 0.75,
			["gyhgtg"] = 0.5,
			["ygbhggv"] = 0.4,
			["jghbjhgyfd"] = Color3.fromRGB(255, 255, 255),
			["shdbsnjfc"] = 0.364,
			["skdjfkdm"] = 0.25,
			["sjdjncdjf"] = Color3.fromRGB(199, 199, 199),
			["efjdjfk"] = Color3.fromRGB(106, 112, 125),
			["sejfd"] = 0,
			["jddfjsd"] = 0,
		},
		["afternoon"] = {
			["yfbghj"] = Color3.fromRGB(138, 138, 138),
			["tgvbyd"] = 15.5,
			["ghuybhuyhj"] = 41.7,
			["khnbfth"] = 2,
			["hgyghkg"] = Color3.fromRGB(0, 0, 0),
			["yfbhjku"] = Color3.fromRGB(0, 0, 0),
			["ygyyfgvhbjytrt"] = 0.25,
			["sdfcddc"] = 0.25,
			["hgnujuu7thgr"] = true,
			["hyhnngtf"] = Color3.fromRGB(138, 138, 138),
			["hdfr7thgr"] = 0.1,
			["fhnchvhfjsd"] = 0.01,
			["ugtbbjhygt"] = 0.15,
			["tfbghuugbnjhg"] = -0.1,
			["fvrtccvghghj"] = Color3.fromRGB(255, 252, 245),
			["jnfdhbnfcvh"] = 0.9,
			["fvtyghj"] = 24,
			["ygbhnj"] = 0.85,
			["njnfg"] = 0,
			["jdfkd"] = 0.15,
			["fvgsdfg"] = 50,
			["sdkvkflv"] = 12,
			["hbjhd"] = 0.75,
			["gyhgtg"] = 0.45,
			["ygbhggv"] = 0.35,
			["jghbjhgyfd"] = Color3.fromRGB(255, 248, 231),
			["shdbsnjfc"] = 0.32,
			["skdjfkdm"] = 0.25,
			["sjdjncdjf"] = Color3.fromRGB(199, 199, 199),
			["efjdjfk"] = Color3.fromRGB(106, 112, 125),
			["sejfd"] = 0.05,
			["jddfjsd"] = 0,
		},
		["evening"] = {
			["yfbghj"] = Color3.fromRGB(150, 112, 90),
			["tgvbyd"] = 17.5,
			["ghuybhuyhj"] = 41.7,
			["khnbfth"] = 2,
			["hgyghkg"] = Color3.fromRGB(0, 0, 0),
			["yfbhjku"] = Color3.fromRGB(255, 176, 131),
			["ygyyfgvhbjytrt"] = 0.25,
			["sdfcddc"] = 0.25,
			["hgnujuu7thgr"] = true,
			["hyhnngtf"] = Color3.fromRGB(150, 112, 90),
			["hdfr7thgr"] = 0.25,
			["fhnchvhfjsd"] = 0.05,
			["ugtbbjhygt"] = 0.2,
			["tfbghuugbnjhg"] = -0.3,
			["fvrtccvghghj"] = Color3.fromRGB(255, 231, 207),
			["jnfdhbnfcvh"] = 1.2,
			["fvtyghj"] = 32,
			["ygbhnj"] = 0.7,
			["njnfg"] = 0,
			["jdfkd"] = 0.2,
			["fvgsdfg"] = 50,
			["sdkvkflv"] = 15,
			["hbjhd"] = 0.8,
			["gyhgtg"] = 0.6,
			["ygbhggv"] = 0.4,
			["jghbjhgyfd"] = Color3.fromRGB(255, 207, 165),
			["shdbsnjfc"] = 0.42,
			["skdjfkdm"] = 0.3,
			["sjdjncdjf"] = Color3.fromRGB(225, 180, 150),
			["efjdjfk"] = Color3.fromRGB(255, 176, 131),
			["sejfd"] = 0.3,
			["jddfjsd"] = 0.1,
		},
		["night"] = {
			["yfbghj"] = Color3.fromRGB(85, 85, 127),
			["tgvbyd"] = 0,
			["ghuybhuyhj"] = 41.7,
			["khnbfth"] = 1,
			["hgyghkg"] = Color3.fromRGB(0, 0, 0),
			["yfbhjku"] = Color3.fromRGB(0, 0, 0),
			["ygyyfgvhbjytrt"] = 0.15,
			["sdfcddc"] = 0.15,
			["hgnujuu7thgr"] = true,
			["hyhnngtf"] = Color3.fromRGB(85, 85, 127),
			["hdfr7thgr"] = -0.2,
			["fhnchvhfjsd"] = -0.1,
			["ugtbbjhygt"] = 0.05,
			["tfbghuugbnjhg"] = -0.5,
			["fvrtccvghghj"] = Color3.fromRGB(200, 210, 255),
			["jnfdhbnfcvh"] = 0.4,
			["fvtyghj"] = 24,
			["ygbhnj"] = 1,
			["njnfg"] = 0,
			["jdfkd"] = 0.1,
			["fvgsdfg"] = 50,
			["sdkvkflv"] = 10,
			["hbjhd"] = 0.75,
			["gyhgtg"] = 0.3,
			["ygbhggv"] = 0.2,
			["jghbjhgyfd"] = Color3.fromRGB(170, 180, 210),
			["shdbsnjfc"] = 0.25,
			["skdjfkdm"] = 0.2,
			["sjdjncdjf"] = Color3.fromRGB(140, 150, 180),
			["efjdjfk"] = Color3.fromRGB(85, 85, 127),
			["sejfd"] = 0,
			["jddfjsd"] = 0.2,
		},
		["midnight"] = {
			["yfbghj"] = Color3.fromRGB(60, 60, 90),
			["tgvbyd"] = 0,
			["ghuybhuyhj"] = 41.7,
			["khnbfth"] = 0.5,
			["hgyghkg"] = Color3.fromRGB(0, 0, 0),
			["yfbhjku"] = Color3.fromRGB(0, 0, 0),
			["ygyyfgvhbjytrt"] = 0.1,
			["sdfcddc"] = 0.1,
			["hgnujuu7thgr"] = true,
			["hyhnngtf"] = Color3.fromRGB(60, 60, 90),
			["hdfr7thgr"] = -0.3,
			["fhnchvhfjsd"] = -0.15,
			["ugtbbjhygt"] = 0,
			["tfbghuugbnjhg"] = -0.6,
			["fvrtccvghghj"] = Color3.fromRGB(180, 190, 230),
			["jnfdhbnfcvh"] = 0.3,
			["fvtyghj"] = 24,
			["ygbhnj"] = 1,
			["njnfg"] = 0,
			["jdfkd"] = 0.05,
			["fvgsdfg"] = 50,
			["sdkvkflv"] = 8,
			["hbjhd"] = 0.7,
			["gyhgtg"] = 0.2,
			["ygbhggv"] = 0.15,
			["jghbjhgyfd"] = Color3.fromRGB(150, 160, 190),
			["shdbsnjfc"] = 0.2,
			["skdjfkdm"] = 0.15,
			["sjdjncdjf"] = Color3.fromRGB(120, 130, 160),
			["efjdjfk"] = Color3.fromRGB(60, 60, 90),
			["sejfd"] = 0,
			["jddfjsd"] = 0.3,
		},
	}

	return presets
end

ShaderFx = {}

-- Crea (una sola vez) y reutiliza nuestros propios efectos en Lighting, para que funcionen
-- en cualquier juego aunque no tenga esos efectos, sin tocar los del juego.
function ShaderFx_Get(class, name)
	local fx = ShaderFx[name]
	if fx and fx.Parent == Lighting then
		return fx
	end
	fx = Instance.new(class)
	fx.Name = name
	fx.Enabled = false
	fx.Parent = Lighting
	ShaderFx[name] = fx
	return fx
end

-- Solo escribe lo que cambio (evita trabajo inutil cada tick)
function ShaderFx_Set(fx, props, enabled)
	for k, v in pairs(props) do
		if fx[k] ~= v then
			fx[k] = v
		end
	end
	if fx.Enabled ~= enabled then
		fx.Enabled = enabled
	end
end

function ShaderFx_Destroy()
	for name, fx in pairs(ShaderFx) do
		pcall(function()
			fx:Destroy()
		end)
		ShaderFx[name] = nil
	end
end

shaderConnection = nil

-- Actualiza un efecto: si se quiere, lo crea/actualiza y lo enciende; si no, lo apaga
function ShaderFx_Update(class, name, props, want)
	if want then
		ShaderFx_Set(ShaderFx_Get(class, name), props, true)
	else
		local fx = ShaderFx[name]
		if fx and fx.Parent and fx.Enabled then
			fx.Enabled = false
		end
	end
end

-- Color Correction y Bloom funcionan SOLOS (aunque Enable Shaders este apagado) y toman sus
-- valores del preset elegido.
function ApplyShaderEffects()
	if not shaderlight then
		ShaderFx_Destroy()
		return
	end
	local boosting = BoostGame ~= nil and BoostGame.Saved ~= nil

	ShaderFx_Update("ColorCorrectionEffect", "BSTShaderColorCorrection", {
		Brightness = shaderlight["fhnchvhfjsd"],
		Contrast = shaderlight["ugtbbjhygt"],
		Saturation = shaderlight["tfbghuugbnjhg"],
		TintColor = shaderlight["fvrtccvghghj"],
	}, shaderWL["cor"] and not boosting)

	ShaderFx_Update("BloomEffect", "BSTShaderBloom", {
		Intensity = shaderlight["jnfdhbnfcvh"],
		Size = shaderlight["fvtyghj"],
		Threshold = shaderlight["ygbhnj"],
	}, shaderWL["bl"] and not boosting)
end

function ApplyShaderLighting()
	if not ShaderSettings.Enabled or not shaderlight then
		if shaderConnection then
			shaderConnection:Disconnect()
			shaderConnection = nil
		end

		Lighting.Ambient = backupLighting.Ambient
		Lighting.ClockTime = backupLighting.ClockTime
		Lighting.GeographicLatitude = backupLighting.GeographicLatitude
		Lighting.Brightness = backupLighting.Brightness
		Lighting.ColorShift_Bottom = backupLighting.ColorShift_Bottom
		Lighting.ColorShift_Top = backupLighting.ColorShift_Top
		Lighting.EnvironmentDiffuseScale = backupLighting.EnvironmentDiffuseScale
		Lighting.EnvironmentSpecularScale = backupLighting.EnvironmentSpecularScale
		if not IsBoosting() and not ShadowSettings.Enabled then
			Lighting.GlobalShadows = backupLighting.GlobalShadows
		end
		Lighting.OutdoorAmbient = backupLighting.OutdoorAmbient
		Lighting.ExposureCompensation = backupLighting.ExposureCompensation
		if not IsBoosting() then
			Lighting.FogEnd = backupLighting.FogEnd
		end
		Lighting.FogColor = backupLighting.FogColor
		Lighting.FogStart = backupLighting.FogStart

		ApplyShaderEffects()

		return
	end

	if not shaderConnection then
		local shAcc = 0
		-- Solo se escribe lo que cambio (escribir Lighting en cada tick sin necesidad causa tirones)
		local function SetP(obj, prop, v)
			if obj[prop] ~= v then
				obj[prop] = v
			end
		end
		-- Igual que SetP pero guarda la niebla que puso el juego (para devolverla con Black Fog)
		local function ShaderFog(prop, v)
			local cur = Lighting[prop]
			if cur ~= v then
				ShaderGameFog[prop] = cur
				Lighting[prop] = v
			end
		end
		shaderConnection = RunService.Heartbeat:Connect(function(dt)
			if not ShaderSettings.Enabled then
				return
			end
			shAcc = shAcc + dt
			if shAcc < 0.1 then
				return
			end
			shAcc = 0

			-- Preset Default + Black Fog: los shaders NO tocan la iluminacion ni la niebla, asi el
			-- juego queda normal con el Black Fog (antes quitaban la niebla del juego y se veia mas negro).
			-- La niebla del juego se devuelve una sola vez y despues no se escribe nada.
			if ShaderIsDefault and Lighting:FindFirstChild("BlackFogConfig") then
				if not ShaderFogReleased then
					ShaderFogReleased = true
					SetP(Lighting, "FogColor", ShaderGameFog.FogColor or backupLighting.FogColor)
					SetP(Lighting, "FogStart", ShaderGameFog.FogStart or backupLighting.FogStart)
					if not IsBoosting() then
						SetP(Lighting, "FogEnd", ShaderGameFog.FogEnd or backupLighting.FogEnd)
					end
				end
				ApplyShaderEffects()
				return
			end
			ShaderFogReleased = false

			SetP(Lighting, "Ambient", shaderlight["yfbghj"])
			SetP(Lighting, "ClockTime", shaderlight["tgvbyd"])
			SetP(Lighting, "GeographicLatitude", shaderlight["ghuybhuyhj"])
			SetP(Lighting, "Brightness", shaderlight["khnbfth"])
			SetP(Lighting, "ColorShift_Bottom", shaderlight["hgyghkg"])
			SetP(Lighting, "ColorShift_Top", shaderlight["yfbhjku"])
			SetP(Lighting, "EnvironmentDiffuseScale", shaderlight["ygyyfgvhbjytrt"])
			SetP(Lighting, "EnvironmentSpecularScale", shaderlight["sdfcddc"])
			if not IsBoosting() and not ShadowSettings.Enabled then
					SetP(Lighting, "GlobalShadows", shaderlight["hgnujuu7thgr"])
				end
			SetP(Lighting, "OutdoorAmbient", shaderlight["hyhnngtf"])
			SetP(Lighting, "ExposureCompensation", shaderlight["hdfr7thgr"])
			if not IsBoosting() then
					ShaderFog("FogEnd", math.huge)
				end
			ShaderFog("FogColor", Color3.fromRGB(255, 255, 255))
			ShaderFog("FogStart", math.huge)

			ApplyShaderEffects()

			local cloud = Lighting:findFirstChild("Clouds")
			local atmosphere = Lighting:findFirstChild("Atmosphere")
				-- No Fog, Black Fog y Boost Game son dueños de la niebla: los shaders no la tocan
				if FogSettings.Enabled or IsBoosting() or Lighting:FindFirstChild("BlackFogConfig") then
					atmosphere = nil
				end

			if cloud then
				SetP(cloud, "Cover", shaderlight["gyhgtg"])
				SetP(cloud, "Density", shaderlight["ygbhggv"])
				SetP(cloud, "Color", shaderlight["jghbjhgyfd"])
			end

			if atmosphere then
				SetP(atmosphere, "Density", shaderlight["shdbsnjfc"])
				SetP(atmosphere, "Offset", shaderlight["skdjfkdm"])
				SetP(atmosphere, "Color", shaderlight["sjdjncdjf"])
				SetP(atmosphere, "Decay", shaderlight["efjdjfk"])
				SetP(atmosphere, "Glare", shaderlight["sejfd"])
				SetP(atmosphere, "Haze", shaderlight["jddfjsd"])
			end
		end)
	end
end

function isTextObject(obj)
	return obj:IsA("StringValue") or obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")
end

function HasFontObject(obj)
	return obj:IsA("TextLabel")
end

function escapePattern(s)
	return (tostring(s):gsub("([^%w])", "%%%1"))
end

NameHiderSettings = {
	Enabled = false,
	MyEnabled = false,
	OthersEnabled = false,
	MyName = player.Name,
	MyLevel = nil,
	MyIcon = nil,
	MyTag = nil,
	MyTagColor = nil,
	CustomPlayers = {},
	TextObjectCache = {},
	DirtyObjects = {},
	Connections = {},
	LastFrameUpdate = 0,
	UpdateInterval = 0.033,
	PlayerFrameCache = {},
}

function getPlayerData(plrName)
	if plrName == player.Name then
		if NameHiderSettings.MyEnabled and NameHiderSettings.MyName then
			return NameHiderSettings.MyName,
				NameHiderSettings.MyLevel,
				NameHiderSettings.MyIcon,
				NameHiderSettings.MyTag,
				NameHiderSettings.MyTagColor
		end
		return
	end
	if not NameHiderSettings.OthersEnabled then
		return
	end
	local d = NameHiderSettings.CustomPlayers[plrName]
	if d then
		return d.Name, d.Level, d.Icon, d.Tag, d.TagColor
	end
end

function hasPlayerName(text, playerName)
	if not text or text == "" then
		return false
	end
	local ok, _ = pcall(function()
		return string.find(text, playerName, 1, true) ~= nil
	end)
	return ok and string.find(text, playerName, 1, true) ~= nil
end

function replaceInObject(obj)
	if not NameHiderSettings.Enabled then
		return
	end
	if not isTextObject(obj) then
		return
	end

	local function getText()
		if obj:IsA("StringValue") then
			return obj.Value
		end
		return obj.Text
	end

	local function setText(v)
		if obj:IsA("StringValue") then
			obj.Value = v
		else
			obj.Text = v
		end
	end

	local text = getText()
	if not text or text == "" then
		return
	end

	local changed = false
	for _, plr in ipairs(Players:GetPlayers()) do
		local newName = select(1, getPlayerData(plr.Name))
		if not newName then
			continue
		end
		if hasPlayerName(text, plr.Name) then
			local pattern = escapePattern(plr.Name)
			local ok, replaced = pcall(function()
				return (text:gsub(pattern, newName))
			end)
			if ok and replaced then
				text = replaced
				changed = true
			end
		end
	end

	if changed then
		setText(text)
	end
end

function updatePlayerFrame(plr)
	if not NameHiderSettings.Enabled then
		return
	end

	local cached = NameHiderSettings.PlayerFrameCache[plr]
	if not cached then
		return
	end

	local newName, newLevel, newIcon, tag, tagColor = getPlayerData(plr.Name)
	if not newName then
		return
	end

	if cached.LastName == newName and cached.LastLevel == newLevel and cached.LastIcon == newIcon then
		return
	end

	local gui = playergui:FindFirstChildWhichIsA("ScreenGui", true) or playergui:FindFirstChild("ScreenGui")
	local namesFrame = gui and gui:FindFirstChild("PlayerNamesFrame")
	if not namesFrame then
		for _, g in ipairs(playergui:GetChildren()) do
			if g:IsA("ScreenGui") then
				namesFrame = g:FindFirstChild("PlayerNamesFrame") or namesFrame
			end
		end
	end
	if not namesFrame then
		return
	end
	local frame = namesFrame:FindFirstChild(plr.Name .. "PlayerFrame")
	if not frame then
		return
	end
	local nameLabel = frame:FindFirstChild("NameLabel")
	local levelLabel = frame:FindFirstChild("LevelLabel")
	local iconLabel = frame:FindFirstChild("IconLabel")
	if nameLabel then
		nameLabel.Text = newName
	end
	if levelLabel then
		if newLevel then
			levelLabel.Text = tostring(newLevel)
			frame.LayoutOrder = -newLevel
		else
			levelLabel.Text = ""
		end
	end
	if iconLabel then
		if newIcon then
			iconLabel.Image = newIcon
		elseif tag and RankData[tag] then
			iconLabel.Image = RankData[tag].Icon
		end
	end

	cached.LastName = newName
	cached.LastLevel = newLevel
	cached.LastIcon = newIcon
end

function markDirty(obj)
	NameHiderSettings.DirtyObjects[obj] = true
end

function addToCache(obj)
	if not isTextObject(obj) then
		return
	end
	if NameHiderSettings.TextObjectCache[obj] then
		return
	end
	local should = false
	local text = obj:IsA("StringValue") and obj.Value or obj.Text
	if text == "" then
		should = true
	end
	for _, plr in ipairs(Players:GetPlayers()) do
		if hasPlayerName(text, plr.Name) then
			should = true
			break
		end
	end
	if should then
		NameHiderSettings.TextObjectCache[obj] = true

		local conn = obj:GetPropertyChangedSignal(obj:IsA("StringValue") and "Value" or "Text"):Connect(function()
			markDirty(obj)
		end)
		table.insert(NameHiderSettings.Connections, conn)

		replaceInObject(obj)
	end
end

function removeFromCache(obj)
	NameHiderSettings.TextObjectCache[obj] = nil
	NameHiderSettings.DirtyObjects[obj] = nil
end

function scanContainer(container)
	pcall(function()
		for _, obj in ipairs(container:GetDescendants()) do
			addToCache(obj)
		end
	end)
end

function connectDescendantSignals(container)
	pcall(function()
		table.insert(
			NameHiderSettings.Connections,
			container.DescendantAdded:Connect(function(obj)
				task.defer(addToCache, obj)
			end)
		)
		table.insert(NameHiderSettings.Connections, container.DescendantRemoving:Connect(removeFromCache))
	end)
end

function hookChatFiltering()
	local chatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
		or ReplicatedStorage:FindFirstChild("Chat")
		or ReplicatedStorage
	local msgEvent = chatEvents and chatEvents:FindFirstChild("OnMessageDoneFiltering")
	if msgEvent and msgEvent:IsA("RemoteEvent") then
		msgEvent.OnClientEvent:Connect(function(data)
			if not NameHiderSettings.Enabled then
				return
			end
			if type(data) ~= "table" then
				return
			end
			local speaker = data.FromSpeaker or data.Speaker or data.SpeakerName or data.Username
			local message = data.Message or data.Text
			if not speaker or not message then
				return
			end
			local plr = Players:FindFirstChild(speaker)
			if not plr then
				return
			end
			local newName, _, _, tag, tagColor = getPlayerData(plr.Name)
			if not newName then
				local formatted = formatChatMessage and formatChatMessage(message, plr) or message
				if formatted and formatted ~= message then
					data.Message = formatted
				end
				return
			end
			local formatted = message
			if tag and tagColor then
				local c = tagColor:gsub("#", "")
				formatted = string.format("<font color='#%s'>[%s]</font> %s", c, tag, formatted)
			end
			data.Message = formatted
		end)
	end
end

function StartNameHider()
	if NameHiderSettings.Enabled then
		return
	end
	NameHiderSettings.Enabled = true

	for _, plr in ipairs(Players:GetPlayers()) do
		NameHiderSettings.PlayerFrameCache[plr] = {
			LastName = nil,
			LastLevel = nil,
			LastIcon = nil,
		}
	end

	scanContainer(workspace)
	scanContainer(CoreGui)
	scanContainer(playergui)
	connectDescendantSignals(workspace)
	connectDescendantSignals(CoreGui)
	connectDescendantSignals(playergui)
	hookChatFiltering()

	table.insert(
		NameHiderSettings.Connections,
		RunService.Heartbeat:Connect(function()
			local now = tick()
			if now - NameHiderSettings.LastFrameUpdate < NameHiderSettings.UpdateInterval then
				return
			end
			NameHiderSettings.LastFrameUpdate = now

			for obj in pairs(NameHiderSettings.DirtyObjects) do
				if not obj or not obj.Parent then
					removeFromCache(obj)
				else
					replaceInObject(obj)
				end
				NameHiderSettings.DirtyObjects[obj] = nil
			end

			if now - (NameHiderSettings.LastPlayerFrameUpdate or 0) >= 0.1 then
				NameHiderSettings.LastPlayerFrameUpdate = now
				for _, plr in ipairs(Players:GetPlayers()) do
					pcall(updatePlayerFrame, plr)
				end
			end
		end)
	)
	for _, plr in ipairs(Players:GetPlayers()) do
		pcall(updatePlayerFrame, plr)
	end
end

function StopNameHider()
	NameHiderSettings.Enabled = false
	for _, c in ipairs(NameHiderSettings.Connections) do
		pcall(function()
			c:Disconnect()
		end)
	end
	NameHiderSettings.Connections = {}
	NameHiderSettings.TextObjectCache = {}
	NameHiderSettings.DirtyObjects = {}
	NameHiderSettings.PlayerFrameCache = {}
end

ConnectionManager = {
	PlayerConnections = {},
	GlobalConnections = {},
	PerPlayerConnections = {},
}

function ConnectionManager:AddGlobal(name, connection)
	if self.GlobalConnections[name] then
		self.GlobalConnections[name]:Disconnect()
	end
	self.GlobalConnections[name] = connection
end

function ConnectionManager:AddPerPlayer(zag, name, connection)
	if not self.PerPlayerConnections[zag] then
		self.PerPlayerConnections[zag] = {}
	end
	if self.PerPlayerConnections[zag][name] then
		self.PerPlayerConnections[zag][name]:Disconnect()
	end
	self.PerPlayerConnections[zag][name] = connection
end

function getmap()
	return map.Value
end

function GetBeast()
	for _, v in Players:GetPlayers() do
		local char = v.Character
		if char and char:FindFirstChild("BeastPowers") then
			return char
		end
	end
end

function GetPartToRope()
	local partToRope = RopeHelperSettings.SelectedPart
	if RopeHelperSettings.RandomizePart then
		local parts = { "Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg" }
		partToRope = parts[math.random(1, #parts)]
	end
	return partToRope
end

function AutoRopePlayer(TargetPlayer)

	local beast = GetBeast()
	if not beast then
		warn("No beast found")
		return
	end

	local Hammer = beast:FindFirstChild("Hammer")
	if not Hammer then
		warn("Beast doesn't have hammer")
		return
	end

	local HammerEvent = Hammer:FindFirstChild("HammerEvent")
	local TargetChar = TargetPlayer.Character
	if not TargetChar then
		warn("No character to rope")
		return
	end

	local partName = GetPartToRope()
	local targetPart = TargetChar:FindFirstChild(partName)
	if not targetPart then
		targetPart = TargetChar:FindFirstChild("Torso")
	end

	if not targetPart then
		warn("No valid part to rope")
		return
	end

	local tempStats = TargetPlayer:FindFirstChild("TempPlayerStatsModule")
	if not tempStats then
		return
	end

	local ragdoll = tempStats:FindFirstChild("Ragdoll")
	if not ragdoll or not ragdoll.Value then
		return
	end

	local args = {
		"HammerTieUp",
		targetPart,
		TargetChar:FindFirstChild("HumanoidRootPart").Position,
	}

	HammerEvent:FireServer(unpack(args))
end

function canHitPlayer(plr)
	local now = tick()
	local lastHit = KillAuraSettings.LastHitTimes[plr] or 0
	if now - lastHit < KillAuraSettings.HitCooldown then
		return false
	end
	KillAuraSettings.LastHitTimes[plr] = now
	return true
end

function getObjectPosition(object)
	if object:IsA("Model") then
		if object.PrimaryPart then
			return object.PrimaryPart.Position
		end
		local cf = object:GetPivot()
		if cf then
			return cf.Position
		end
		for _, child in pairs(object:GetDescendants()) do
			if child:IsA("BasePart") then
				return child.Position
			end
		end
	elseif object:IsA("BasePart") then
		return object.Position
	else
		for _, child in pairs(object:GetDescendants()) do
			if child:IsA("BasePart") then
				return child.Position
			end
		end
	end
	return Vector3.new(0, 0, 0)
end

function findNearestObject(playerPosition, objectList)
	local nearestObject = nil
	local shortestDistance = math.huge
	for _, object in pairs(objectList) do
		if object.Parent then
			local objectPosition = getObjectPosition(object)
			local distance = (playerPosition - objectPosition).Magnitude
			if distance < shortestDistance then
				shortestDistance = distance
				nearestObject = object
			end
		end
	end
	return nearestObject, shortestDistance
end

function getIsTreeBush(Size)
	local x = Size.X
	local y = Size.Y
	local z = Size.Z

	if x >= 6 and x <= 14 then
		if y >= 7 and x <= 14 then
			if z >= 7 and z <= 14 then
				return true
			end
		end
	end

	return false
end

function HitPlayer(TargetPlayer)
	local beast = GetBeast()
	if not beast then
		return
	end
	local Hammer = beast:FindFirstChild("Hammer")
	if not Hammer then
		return
	end
	local HammerEvent = Hammer:FindFirstChild("HammerEvent")
	local HRP = TargetPlayer.Character and TargetPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not HRP then
		return
	end
	HammerEvent:FireServer("HammerHit", HRP, HRP.Position)
end
function StartKillAura()
	if KillAuraSettings.Connection then
		KillAuraSettings.Connection:Disconnect()
	end

	local kaAcc = 0
	KillAuraSettings.Connection = RunService.Heartbeat:Connect(function(dt)
		if not KillAuraSettings.Enabled then
			return
		end
		kaAcc = kaAcc + dt
		if kaAcc < 0.05 then
			return
		end
		kaAcc = 0

		local myChar = player.Character
		if not myChar or not myChar:FindFirstChild("HumanoidRootPart") or not myChar:FindFirstChild("BeastPowers") then
			return
		end

		local myHrp = myChar.HumanoidRootPart

		for _, plr in pairs(Players:GetPlayers()) do
			if plr.Character then
				local targetHrp = plr.Character:FindFirstChild("HumanoidRootPart")
				if targetHrp and canHitPlayer(plr) then
					local distance = (myHrp.Position - targetHrp.Position).Magnitude
					if distance <= KillAuraSettings.MaxDistance then
						HitPlayer(plr)
					end
				end
			end
		end
	end)
end

-- ============================================================
-- ESP (optimizado). Todo lo que crea el script se llama "EspX" para no chocar con ESP externos.
--  * Los Highlights se guardan en tablas (no se buscan por nombre/clase en cada update).
--  * Solo se escribe una propiedad si de verdad cambio (cache por Highlight).
--  * Clone ESP: clones ligeros (sin colision/query/touch), soldados con WeldConstraint dentro del
--    propio modelo EspX (no se toca el personaje ni sus Motor6D), y se arma todo antes de parentar.
-- ============================================================
HlCache = setmetatable({}, { __mode = "k" }) -- [Highlight] = ultimos valores aplicados
EspPlayers = {} -- [Character] = Highlight
EspCloneHidden = {} -- [Character] = { partes originales ocultadas por el Clone ESP }

function SetHl(hl, fillColor, outlineColor, fillTransparency, outlineTransparency)
	local c = HlCache[hl]
	if not c then
		c = {}
		HlCache[hl] = c
	end
	if c.fc ~= fillColor then
		c.fc = fillColor
		hl.FillColor = fillColor
	end
	if c.oc ~= outlineColor then
		c.oc = outlineColor
		hl.OutlineColor = outlineColor
	end
	if c.ft ~= fillTransparency then
		c.ft = fillTransparency
		hl.FillTransparency = fillTransparency
	end
	if c.ot ~= outlineTransparency then
		c.ot = outlineTransparency
		hl.OutlineTransparency = outlineTransparency
	end
end

function ApplyHighlightColors(Highlight, Character)
	local e = Settings.EspSettings.PlayerEsp
	if Character:FindFirstChild("BeastPowers") then
		SetHl(Highlight, e.BeastFillColor, e.BeastOutlineColor, e.BeastFillTransparancy, e.BeastOutlineTransparancy)
	else
		SetHl(
			Highlight,
			e.SurvivorFillColor,
			e.SurvivorOutlineColor,
			e.SurvivorFillTransparancy,
			e.SurvivorOutlineTransparancy
		)
	end
end

local function DestroyPlayerEspInstance(Character)
	local old = Character:FindFirstChild("EspX")
	if old then
		old:Destroy()
	end
	EspPlayers[Character] = nil
end

function AddNormalEsp(Character)
	DestroyPlayerEspInstance(Character)
	local highlight = Instance.new("Highlight")
	highlight.Name = "EspX"
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	ApplyHighlightColors(highlight, Character)
	highlight.Parent = Character
	EspPlayers[Character] = highlight
end

function AddCloneEsp(Character)
	DestroyPlayerEspInstance(Character)

	-- Se arma TODO fuera del workspace y se parenta al final (1 sola vez)
	local espModel = Instance.new("Model")
	espModel.Name = "EspX"

	local hidden = {}
	for _, part in ipairs(Character:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" and part.Transparency < 0.99 then
			local clone = part:Clone()

			-- Solo quedan las mallas (forma); scripts, sonidos, joints, etc. se descartan
			for _, child in ipairs(clone:GetChildren()) do
				if not (child:IsA("SpecialMesh") or child:IsA("Mesh") or child:IsA("CharacterMesh")) then
					child:Destroy()
				end
			end

			clone.Transparency = 0
			clone.Anchored = false
			clone.CanCollide = false
			clone.CanTouch = false -- no dispara Touched del juego
			clone.CanQuery = false -- no estorba raycasts del juego
			clone.Massless = true
			clone.CastShadow = false
			clone.Name = "EspX"

			local weld = Instance.new("WeldConstraint")
			weld.Name = "EspX"
			weld.Part0 = part
			weld.Part1 = clone
			weld.Parent = clone
			clone.Parent = espModel

			hidden[#hidden + 1] = part
		end
	end

	local highlight = Instance.new("Highlight")
	highlight.Name = "EspX"
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Adornee = espModel
	ApplyHighlightColors(highlight, Character)
	highlight.Parent = espModel

	espModel.Parent = Character
	for i = 1, #hidden do
		hidden[i].LocalTransparencyModifier = 1
	end

	EspCloneHidden[Character] = hidden
	EspPlayers[Character] = highlight
end

function AddPlayerEsp(Character)
	if Settings.EspSettings.PlayerEsp.UseSkeletonEsp then
		return
	end
	if Settings.EspSettings.PlayerEsp.UseCloneEsp then
		AddCloneEsp(Character)
	else
		AddNormalEsp(Character)
	end
end

function RemovePlayerEsp(Character)
	DestroyPlayerEspInstance(Character)
	-- Solo se restaura lo que el Clone ESP oculto (antes se recorria todo el personaje)
	local hidden = EspCloneHidden[Character]
	if hidden then
		for i = 1, #hidden do
			local p = hidden[i]
			if p.Parent then
				p.LocalTransparencyModifier = 0
			end
		end
		EspCloneHidden[Character] = nil
	end
end

function UpdatePlayerEsp()
	local pe = Settings.EspSettings.PlayerEsp
	if not pe.Enabled or pe.UseSkeletonEsp then
		return
	end
	for char, hl in pairs(EspPlayers) do
		if hl.Parent and char.Parent then
			ApplyHighlightColors(hl, char)
		else
			EspPlayers[char] = nil
			EspCloneHidden[char] = nil
		end
	end
end

function ReloadPlayerEsp()
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Character and plr ~= player then
			RemovePlayerEsp(plr.Character)
			if Settings.EspSettings.PlayerEsp.Enabled and not Settings.EspSettings.PlayerEsp.UseSkeletonEsp then
				AddPlayerEsp(plr.Character)
			end
		end
	end
end

function UpdateRainbowEsp(dt)
	if not RainbowEspState.Enabled or not Settings.EspSettings.PlayerEsp.Enabled then
		return
	end

	-- Speed se expresa en grados por frame a 60 FPS; se escala con el tiempo real
	RainbowEspState.Hue = (RainbowEspState.Hue + RainbowEspState.Speed * 60 * (dt or (1 / 60))) % 360
	local rainbowColor = Color3.fromHSV(RainbowEspState.Hue / 360, 1, 1)

	Settings.EspSettings.PlayerEsp.SurvivorFillColor = rainbowColor
	Settings.EspSettings.PlayerEsp.BeastFillColor = rainbowColor

	UpdatePlayerEsp()
end

function StartRainbowEsp()
	if RainbowEspState.Connection then
		RainbowEspState.Connection:Disconnect()
	end

	local reAcc = 0
	RainbowEspState.Connection = RunService.Heartbeat:Connect(function(dt)
		reAcc = reAcc + dt
		if reAcc < 0.033 then
			return
		end
		local step = reAcc
		reAcc = 0
		UpdateRainbowEsp(step)
	end)
end

function StopRainbowEsp()
	if RainbowEspState.Connection then
		RainbowEspState.Connection:Disconnect()
		RainbowEspState.Connection = nil
	end
end

-- ===== Computer ESP =====
-- Mismo criterio que bom_bom: pantalla verde = PC terminada, si no usa el Pc Fill normal
local function IsPcDone(screen)
	local c = screen.BrickColor.Color
	return c.G > c.B and c.G > c.R + 0.15
end

local function ApplyPcHl(d)
	local cfg = Settings.EspSettings.PcEsp
	SetHl(
		d.Hl,
		d.Done and cfg.DoneFillColor or cfg.FillColor,
		cfg.OutlineColor,
		cfg.FillTransparency,
		cfg.OutlineTransparency
	)
end

function StopPcEsp()
	for _, d in pairs(PlayerConnections.PcEsp) do
		if d.Conn then
			d.Conn:Disconnect()
		end
		if d.Hl then
			d.Hl:Destroy()
		end
	end
	PlayerConnections.PcEsp = {}
end

function StartPcEsp()
	StopPcEsp()
	local themap = map.Value
	if not themap then
		return
	end
	for _, v in ipairs(themap:GetChildren()) do
		if v.Name == "ComputerTable" then
			local screen = v:FindFirstChild("Screen")
			if screen then
				local d = { Hl = Instance.new("Highlight"), Screen = screen, Done = IsPcDone(screen) }
				d.Hl.Name = "EspX"
				ApplyPcHl(d)
				d.Hl.Parent = v
				-- Un solo evento por PC; solo recalcula cuando cambia el estado (terminada / no)
				d.Conn = screen:GetPropertyChangedSignal("BrickColor"):Connect(function()
					local done = IsPcDone(screen)
					if done ~= d.Done then
						d.Done = done
						ApplyPcHl(d)
					end
				end)
				PlayerConnections.PcEsp[v] = d
			end
		end
	end
end

-- Los pickers disparan el callback muchas veces mientras se arrastra: se junta todo en 1 update por frame
local pcDirty = false
function UpdatePcEspColors()
	if pcDirty then
		return
	end
	pcDirty = true
	task.defer(function()
		pcDirty = false
		for _, d in pairs(PlayerConnections.PcEsp) do
			if d.Hl.Parent then
				ApplyPcHl(d)
			end
		end
	end)
end

-- ===== Tube ESP =====
function StopTubeEsp()
	for _, highlight in pairs(PlayerConnections.TubeEsp) do
		highlight:Destroy()
	end
	PlayerConnections.TubeEsp = {}
end

function StartTubeEsp()
	StopTubeEsp()
	local themap = map.Value
	if not themap then
		return
	end
	local cfg = Settings.EspSettings.TubeEsp
	for _, v in ipairs(themap:GetChildren()) do
		if v.Name == "FreezePod" then
			local highlight = Instance.new("Highlight")
			highlight.Name = "EspX"
			SetHl(highlight, cfg.FillColor, cfg.OutlineColor, cfg.FillTransparency, cfg.OutlineTransparency)
			highlight.Parent = v
			PlayerConnections.TubeEsp[v] = highlight
		end
	end
end

local tubeDirty = false
function UpdateTubeEspColors()
	if tubeDirty then
		return
	end
	tubeDirty = true
	task.defer(function()
		tubeDirty = false
		local cfg = Settings.EspSettings.TubeEsp
		for _, highlight in pairs(PlayerConnections.TubeEsp) do
			if highlight.Parent then
				SetHl(highlight, cfg.FillColor, cfg.OutlineColor, cfg.FillTransparency, cfg.OutlineTransparency)
			end
		end
	end)
end

-- ===== Exit ESP =====
function StopExitEsp()
	for _, highlight in pairs(PlayerConnections.ExitEsp) do
		highlight:Destroy()
	end
	PlayerConnections.ExitEsp = {}
end

function StartExitEsp()
	StopExitEsp()
	local themap = map.Value
	if not themap then
		return
	end
	local cfg = Settings.EspSettings.ExitEsp
	for _, v in ipairs(themap:GetChildren()) do
		if v.Name == "ExitDoor" then
			local highlight = Instance.new("Highlight")
			highlight.Name = "EspX"
			SetHl(highlight, cfg.FillColor, cfg.OutlineColor, cfg.FillTransparency, cfg.OutlineTransparency)
			highlight.Parent = v
			PlayerConnections.ExitEsp[v] = highlight
		end
	end
end

local exitDirty = false
function UpdateExitEspColors()
	if exitDirty then
		return
	end
	exitDirty = true
	task.defer(function()
		exitDirty = false
		local cfg = Settings.EspSettings.ExitEsp
		for _, highlight in pairs(PlayerConnections.ExitEsp) do
			if highlight.Parent then
				SetHl(highlight, cfg.FillColor, cfg.OutlineColor, cfg.FillTransparency, cfg.OutlineTransparency)
			end
		end
	end)
end

function UpdateDoorEspColors()
	local doorsManager = workspace:FindFirstChild("EspX_Doors")
	if not doorsManager then
		return
	end

	local openModel = doorsManager:FindFirstChild("Open")
	local closedModel = doorsManager:FindFirstChild("Closed")

	if openModel then
		local openHighlight = openModel:FindFirstChild("EspX")
		if openHighlight then
			openHighlight.FillColor = Settings.EspSettings.DoorEsp.OpenColor
			openHighlight.OutlineColor = Settings.EspSettings.DoorEsp.OpenOutlineColor
			openHighlight.OutlineTransparency = Settings.EspSettings.DoorEsp.OutlineTransparency
			openHighlight.FillTransparency = Settings.EspSettings.DoorEsp.OpenFillTransparency
		end
	end

	if closedModel then
		local closedHighlight = closedModel:FindFirstChild("EspX")
		if closedHighlight then
			closedHighlight.FillColor = Settings.EspSettings.DoorEsp.ClosedColor
			closedHighlight.OutlineColor = Settings.EspSettings.DoorEsp.ClosedOutlineColor
			closedHighlight.OutlineTransparency = Settings.EspSettings.DoorEsp.OutlineTransparency
			closedHighlight.FillTransparency = Settings.EspSettings.DoorEsp.ClosedFillTransparency
		end
	end
end

function StopDoorEsp()
	local originalMap = getmap()

	for doorModel, conn in pairs(PlayerConnections.DoorEsp) do
		if conn then
			conn:Disconnect()
		end
	end

	local doorsManager = workspace:FindFirstChild("EspX_Doors")
	if doorsManager and originalMap then
		local openModel = doorsManager:FindFirstChild("Open")
		local closedModel = doorsManager:FindFirstChild("Closed")

		if openModel then
			for _, door in pairs(openModel:GetChildren()) do
				if door:IsA("Model") then
					door.Parent = originalMap
				end
			end
		end

		if closedModel then
			for _, door in pairs(closedModel:GetChildren()) do
				if door:IsA("Model") then
					door.Parent = originalMap
				end
			end
		end
	end

	PlayerConnections.DoorEsp = {}

	if doorsManager then
		doorsManager:Destroy()
	end
end

function DoorEsp()
	StopDoorEsp()
	local themap = map.Value
	if not themap then
		return
	end

	local OpenedGroup = Instance.new("Model")
	OpenedGroup.Parent = workspace
	OpenedGroup.Name = "EspX_Doors"

	local Open = Instance.new("Model")
	Open.Parent = OpenedGroup
	Open.Name = "Open"

	local Closed = Instance.new("Model")
	Closed.Parent = OpenedGroup
	Closed.Name = "Closed"

	local openhl = Instance.new("Highlight")
	openhl.FillColor = Settings.EspSettings.DoorEsp.OpenColor
	openhl.OutlineColor = Settings.EspSettings.DoorEsp.OpenOutlineColor
	openhl.OutlineTransparency = Settings.EspSettings.DoorEsp.OutlineTransparency
	openhl.FillTransparency = Settings.EspSettings.DoorEsp.OpenFillTransparency
	openhl.Name = "EspX"
	openhl.Parent = Open

	local closedhl = Instance.new("Highlight")
	closedhl.FillColor = Settings.EspSettings.DoorEsp.ClosedColor
	closedhl.OutlineColor = Settings.EspSettings.DoorEsp.ClosedOutlineColor
	closedhl.OutlineTransparency = Settings.EspSettings.DoorEsp.OutlineTransparency
	closedhl.FillTransparency = Settings.EspSettings.DoorEsp.ClosedFillTransparency
	closedhl.Name = "EspX"
	closedhl.Parent = Closed

	for _, v in pairs(themap:GetChildren()) do
		if v.Name == "SingleDoor" or v.Name == "DoubleDoor" then
			local trigger = v:FindFirstChild("DoorTrigger")
			if trigger then
				local actionsign = trigger:FindFirstChild("ActionSign")
				if actionsign then
					if actionsign.Value == 11 then
						v.Parent = Open
					else
						v.Parent = Closed
					end
					local conn = actionsign:GetPropertyChangedSignal("Value"):Connect(function()
						if actionsign.Value == 11 then
							v.Parent = Open
						else
							v.Parent = Closed
						end
					end)
					PlayerConnections.DoorEsp[v] = conn
				end
			end
		end
	end
end

function getCharacterParts(character)
	return {
		Head = character:FindFirstChild("Head"),
		Torso = character:FindFirstChild("Torso"),
		LeftArm = character:FindFirstChild("Left Arm"),
		RightArm = character:FindFirstChild("Right Arm"),
		LeftLeg = character:FindFirstChild("Left Leg"),
		RightLeg = character:FindFirstChild("Right Leg"),
	}
end

function getSkeletonJoints()
	return {
		{ "Head", "Torso" },
		{ "Torso", "LeftArm" },
		{ "Torso", "RightArm" },
		{ "Torso", "LeftLeg" },
		{ "Torso", "RightLeg" },
	}
end

function createSkeletonUI(character)
	if SkeletonUIs[character] then
		return SkeletonUIs[character]
	end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end

	local parts = getCharacterParts(character)
	if not parts.Head or not parts.Torso then
		return
	end

	local lines = {}
	local joints = getSkeletonJoints()

	for _, joint in pairs(joints) do
		local line = Drawing.new("Line")
		line.Thickness = Settings.EspSettings.PlayerEsp.SkeletonSettings.Thickness
		line.Color = Settings.EspSettings.PlayerEsp.SkeletonSettings.Color
		line.Transparency = Settings.EspSettings.PlayerEsp.SkeletonSettings.Transparency
		line.Visible = false
		lines[joint[1] .. "_" .. joint[2]] = line
	end

	SkeletonUIs[character] = lines

	local skParts, skLastScan = nil, 0

	-- Las llaves de las lineas se arman una sola vez (antes se concatenaban strings en cada frame)
	local jointData = {}
	for _, joint in pairs(joints) do
		jointData[#jointData + 1] = { joint[1], joint[2], lines[joint[1] .. "_" .. joint[2]] }
	end

	-- Partes unicas del esqueleto: cada una se proyecta a pantalla UNA vez por frame
	-- (antes se proyectaba 2 veces por articulacion, y el Torso se repetia en casi todas)
	local partList, seenName = {}, {}
	for i = 1, #jointData do
		for k = 1, 2 do
			local n = jointData[i][k]
			if not seenName[n] then
				seenName[n] = true
				partList[#partList + 1] = n
			end
		end
	end
	local sx, sy, sz, son = {}, {}, {}, {}

	SkeletonConnections[character] = RunService.RenderStepped:Connect(function()
		if not character or not character.Parent or not character:FindFirstChild("HumanoidRootPart") then
			return
		end

		local cam = workspace.CurrentCamera
		local skNow = os.clock()
		if not skParts or skNow - skLastScan > 0.5 then
			skLastScan = skNow
			skParts = getCharacterParts(character)
		end
		local parts = skParts

		for i = 1, #partList do
			local name = partList[i]
			local p = parts[name]
			if p then
				local v, on = cam:WorldToViewportPoint(p.Position)
				sx[name], sy[name], sz[name], son[name] = v.X, v.Y, v.Z, on
			end
		end

		for i = 1, #jointData do
			local jd = jointData[i]
			local n1, n2 = jd[1], jd[2]
			local line = jd[3]

			if parts[n1] and parts[n2] and line then
				if son[n1] and son[n2] and sz[n1] > 0 and sz[n2] > 0 then
					line.From = Vector2.new(sx[n1], sy[n1])
					line.To = Vector2.new(sx[n2], sy[n2])
					line.Visible = true
				else
					line.Visible = false
				end
			end
		end
	end)

	return lines
end

function removeSkeletonUI(character)
	if SkeletonConnections[character] then
		SkeletonConnections[character]:Disconnect()
		SkeletonConnections[character] = nil
	end
	if SkeletonUIs[character] then
		for _, line in pairs(SkeletonUIs[character]) do
			if line and line.Remove then
				line:Remove()
			end
		end
		SkeletonUIs[character] = nil
	end
end

function startTracers()
	stopTracers()
	local ts = Settings.EspSettings.PlayerEsp.TracerSettings
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= player then
			local line = Drawing.new("Line")
			line.Color = ts.Color or Color3.new(0, 1, 0)
			line.Thickness = ts.Thickness or 2
			line.Transparency = 1
			line.Visible = false
			TracerLines[plr] = line
		end
	end

	-- UNA sola conexion para todos los tracers (antes era una por jugador, seteando 6 propiedades por frame)
	TracerConnections[1] = RunService.PreRender:Connect(function()
		local cam = workspace.CurrentCamera
		local vp = cam.ViewportSize
		local from = Vector2.new(vp.X / 2, ts.FromBottom == true and vp.Y or vp.Y / 2)
		local enabled = ts.Enabled
		for plr, line in pairs(TracerLines) do
			local char = plr.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if enabled and hrp then
				local pos, onScreen = cam:WorldToViewportPoint(hrp.Position)
				if onScreen then
					line.From = from
					line.To = Vector2.new(pos.X, pos.Y)
					line.Visible = true
				else
					line.Visible = false
				end
			else
				line.Visible = false
			end
		end
	end)
end

function stopTracers()
	for _, conn in pairs(TracerConnections) do
		conn:Disconnect()
	end
	TracerConnections = {}
	for _, line in pairs(TracerLines) do
		line:Remove()
	end
	TracerLines = {}
end

function UpdateTracers()
	local tracerSettings = Settings.EspSettings.PlayerEsp.TracerSettings
	for _, line in pairs(TracerLines) do
		line.Color = tracerSettings.Color
		line.Thickness = tracerSettings.Thickness
		if not tracerSettings.Enabled then
			line.Visible = false
		end
	end
end

function stopSkeletonEsp()
	for character, _ in pairs(SkeletonConnections) do
		removeSkeletonUI(character)
	end
end

function startSkeleton()
	stopSkeletonEsp()
	for _, plr in pairs(Players:GetPlayers()) do
		if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
			createSkeletonUI(plr.Character)
		end
	end
end

function UpdateSkeleton()
	local skelSettings = Settings.EspSettings.PlayerEsp.SkeletonSettings

	for character, lines in pairs(SkeletonUIs) do
		for _, line in pairs(lines) do
			if line then
				line.Color = skelSettings.Color
				line.Thickness = skelSettings.Thickness
				line.Transparency = skelSettings.Transparency
				if not Settings.EspSettings.PlayerEsp.UseSkeletonEsp then
					line.Visible = false
				end
			end
		end
	end

	if not Settings.EspSettings.PlayerEsp.UseSkeletonEsp then
		for character, lines in pairs(SkeletonUIs) do
			for _, line in pairs(lines) do
				if line then
					line.Visible = false
				end
			end
		end
	end
end

function CreateRunnerTimerLabel(plr)
	local character = plr.Character
	if character then
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if humanoidRootPart then
			local billboard = humanoidRootPart:FindFirstChild("BeastPowerBillboard")
			if not billboard then
				billboard = Instance.new("BillboardGui")
				billboard.Name = "BeastPowerBillboard"
				billboard.Size = UDim2.new(2, 0, 1, 0)
				billboard.StudsOffset = Vector3.new(0, 3, 0)
				billboard.AlwaysOnTop = true
				billboard.LightInfluence = 1
				billboard.Parent = humanoidRootPart

				local label = Instance.new("TextLabel")
				label.Name = "BeastPowerLabel"
				label.Size = UDim2.new(1, 0, 1, 0)
				label.BackgroundTransparency = 1
				label.Font = Enum.Font.Arcade
				label.TextSize = 20
				label.Text = ""
				label.TextStrokeTransparency = 0.5
				label.TextColor3 = Settings.GadgetSettings.ProgressSettings.RunnerTimer.TextColor
				label.TextStrokeColor3 = Color3.new(0, 0, 0)
				label.Parent = billboard
			else
				local label = billboard:FindFirstChild("BeastPowerLabel")
				if label then
					local color = Settings.GadgetSettings.ProgressSettings.RunnerTimer.TextColor
					if label.TextColor3 ~= color then
						label.TextColor3 = color
					end
				end
				return label
			end
			return billboard:FindFirstChild("BeastPowerLabel")
		end
	end
	return nil
end
function EnsureAllBillboardsExist()
	for _, plr in pairs(Players:GetPlayers()) do
		if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
			CreateRunnerTimerLabel(plr)
		end
	end
end

function UpdateRunnerTimerColor()
	for _, plr in pairs(Players:GetPlayers()) do
		if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
			local billboard = plr.Character.HumanoidRootPart:FindFirstChild("BeastPowerBillboard")
			if billboard then
				local label = billboard:FindFirstChild("BeastPowerLabel")
				if label then
					label.TextColor3 = Settings.GadgetSettings.ProgressSettings.RunnerTimer.TextColor
				end
			end
		end
	end
end

_lastRunnerLabel = nil

function UpdateRunnerTimer()
	local beast = GetBeast()
	if not beast then
		return
	end

	local beastPlayer = Players:GetPlayerFromCharacter(beast)
	if not beastPlayer then
		return
	end

	local label = CreateRunnerTimerLabel(beastPlayer)

	-- Si cambio el beast, limpia solo el label anterior (antes se recorrian todos los jugadores en cada tick)
	if _lastRunnerLabel and _lastRunnerLabel ~= label and _lastRunnerLabel.Parent then
		_lastRunnerLabel.Text = ""
	end
	_lastRunnerLabel = label

	if label then
		local beastPowers = beast:FindFirstChild("BeastPowers")
		if beastPowers then
			local numberValue = beastPowers:FindFirstChildOfClass("NumberValue")
			if numberValue then
				local v = numberValue.Value
				local previousV = previousValues[beastPlayer.UserId] or v
				local state = runnerStates[beastPlayer.UserId] or "cooldown"

				if v < previousV and v < 1 then
					state = "active"
				elseif v > previousV or v >= 1 then
					state = "cooldown"
				end

				runnerStates[beastPlayer.UserId] = state

				local newText
				if Settings.GadgetSettings.ProgressSettings.RunnerTimer.DisplaySeconds then
					if v >= 1 then
						newText = ""
					elseif state == "active" then
						newText = string.format("%.3fs", v * 3)
					else
						newText = string.format("%.3fs", (1 - v) * 22)
					end
				else
					newText = string.format("%.1f%%", v * 100)
				end
				if label.Text ~= newText then
					label.Text = newText
				end

				previousValues[beastPlayer.UserId] = v
			else
				label.Text = ""
			end
		else
			label.Text = ""
		end
	end
end

function StopRunnerTimer()
	if Settings.GadgetSettings.ProgressSettings.RunnerTimer.Connection then
		Settings.GadgetSettings.ProgressSettings.RunnerTimer.Connection:Disconnect()
		Settings.GadgetSettings.ProgressSettings.RunnerTimer.Connection = nil
	end
	for _, plr in pairs(Players:GetPlayers()) do
		if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
			local billboard = plr.Character.HumanoidRootPart:FindFirstChild("BeastPowerBillboard")
			if billboard then
				local label = billboard:FindFirstChild("BeastPowerLabel")
				if label then
					label.Text = ""
				end
			end
		end
	end
	runnerStates = {}
end

function StartRunnerTimer()
	StopRunnerTimer()

	EnsureAllBillboardsExist()

	local connection = RunService.Heartbeat:Connect(function(deltaTime)
		if not Settings.GadgetSettings.ProgressSettings.RunnerTimer.Enabled then
			StopRunnerTimer()
			return
		end
		local currentTime = tick()
		if currentTime - lastUpdate >= UPDATE_INTERVAL then
			lastUpdate = currentTime
			UpdateRunnerTimer()
		end
	end)
	Settings.GadgetSettings.ProgressSettings.RunnerTimer.Connection = connection
end

function UpdateGetupTimerColors()
	for plr, uiData in pairs(GetupUis) do
		if uiData and uiData.timerLabel then
			local tempStats = plr:FindFirstChild("TempPlayerStatsModule")
			if tempStats then
				local actionProgress = tempStats:FindFirstChild("ActionProgress")
				if actionProgress then
					local secondsLeft = (1 - actionProgress.Value) * c
					uiData.timerLabel.TextColor3 = secondsLeft
								<= Settings.GadgetSettings.ProgressSettings.GetupTimer.WhenToHit
							and Settings.GadgetSettings.ProgressSettings.GetupTimer.HitColor
						or Settings.GadgetSettings.ProgressSettings.GetupTimer.NotHitColor
				end
			end
		end
	end

	for _, plr in pairs(Players:GetPlayers()) do
		if plr.Character then
			local head = plr.Character:FindFirstChild("Head")
			if head then
				local countdown = head:FindFirstChild("RagdollCountdown")
				if countdown then
					local label = countdown:FindFirstChild("CountdownLabel")
					if label then
						local tempStats = plr:FindFirstChild("TempPlayerStatsModule")
						if tempStats then
							local actionProgress = tempStats:FindFirstChild("ActionProgress")
							if actionProgress then
								local secondsLeft = (1 - actionProgress.Value) * c
								label.TextColor3 = secondsLeft
											<= Settings.GadgetSettings.ProgressSettings.GetupTimer.WhenToHit
										and Settings.GadgetSettings.ProgressSettings.GetupTimer.HitColor
									or Settings.GadgetSettings.ProgressSettings.GetupTimer.NotHitColor
							end
						end
					end
				end
			end
		end
	end
end

function CreateGetupTimerLabel(head)
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Name = "RagdollCountdown"
	billboardGui.AlwaysOnTop = true
	billboardGui.Size = UDim2.new(3, 0, 1, 0)
	billboardGui.StudsOffset = Vector3.new(0, 3, 0)
	billboardGui.Parent = head

	local label = Instance.new("TextLabel")
	label.Name = "CountdownLabel"
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.TextColor3 = Settings.GadgetSettings.ProgressSettings.GetupTimer.NotHitColor
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.Text = ""
	label.Parent = billboardGui

	return billboardGui, label
end

function RemoveGetupTimerLabel(head)
	local countdown = head:FindFirstChild("RagdollCountdown")
	if countdown then
		countdown:Destroy()
	end
end

function updateUIPositions()
	local screenHeight = 1
	local baseY = 0.94
	local yStep = 0.1

	for i, plr in pairs(HitPlayers) do
		local uiData = GetupUis[plr]
		if uiData then
			local frame = uiData.frame
			local yOffset = (i - 1) * yStep
			frame.Position = UDim2.new(1, 0, baseY - yOffset, 0)
			frame.AnchorPoint = Vector2.new(1, 1)
		end
	end
end

function removeBottomRightUI(plr)
	if GetupUis[plr] then
		GetupUis[plr].screenGui:Destroy()
		GetupUis[plr] = nil
		updateUIPositions()
	end
end

function updateBottomRightUI(plr, actionProgress)
	if not GetupUis[plr] then
		local screenGui = Instance.new("ScreenGui")
		screenGui.Name = "RagdollUI"
		screenGui.Parent = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui")

		local frame = Instance.new("Frame")
		frame.Size = UDim2.new(0.15, 0, 0.08, 0)
		frame.BackgroundTransparency = 1
		frame.Parent = screenGui

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "PlayerNameLabel"
		nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
		nameLabel.Position = UDim2.new(0, 0, 0, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.TextScaled = true
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.TextStrokeTransparency = 0
		nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
		nameLabel.Text = ""
		nameLabel.Parent = frame

		local timerLabel = Instance.new("TextLabel")
		timerLabel.Name = "TimerLabel"
		timerLabel.Size = UDim2.new(1, 0, 0.5, 0)
		timerLabel.Position = UDim2.new(0, 0, 0.5, 0)
		timerLabel.BackgroundTransparency = 1
		timerLabel.TextScaled = true
		timerLabel.TextColor3 = Settings.GadgetSettings.ProgressSettings.GetupTimer.NotHitColor
		timerLabel.TextStrokeTransparency = 0
		timerLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
		timerLabel.Text = ""
		timerLabel.Parent = frame

		GetupUis[plr] = { screenGui = screenGui, frame = frame, timerLabel = timerLabel, nameLabel = nameLabel }
		updateUIPositions()
	end

	local uiData = GetupUis[plr]
	local timerLabel = uiData.timerLabel
	local nameLabel = uiData.nameLabel

	if not Settings.GadgetSettings.ProgressSettings.GetupTimer.Enabled then
		timerLabel.Text = ""
		nameLabel.Text = ""
		return
	end

	-- Esto corre en cada tick del Getup Timer. Los TextLabel son TextScaled: cada vez que se escribe
	-- el texto el motor recalcula el tamano de la letra. Antes el nombre (que casi nunca cambia) y el
	-- color se reescribian en cada tick; ahora solo se escribe cuando el valor de verdad cambio.
	-- Se sigue llamando getPlayerData en cada tick, asi que si cambia el nombre (Name Hider) se actualiza igual.
	local gSettings = Settings.GadgetSettings.ProgressSettings.GetupTimer
	local secondsLeft = (1 - actionProgress) * c
	local newName, _, _, tag, tagColor = getPlayerData(plr.Name)
	local shownName = newName or plr.Name
	if nameLabel.Text ~= shownName then
		nameLabel.Text = shownName
	end
	local timerText = string.format("%.3f", secondsLeft)
	if timerLabel.Text ~= timerText then
		timerLabel.Text = timerText
	end
	local timerColor = secondsLeft <= gSettings.WhenToHit and gSettings.HitColor or gSettings.NotHitColor
	if timerLabel.TextColor3 ~= timerColor then
		timerLabel.TextColor3 = timerColor
	end
end

function startRagdollCountdown(plr, ragdoll, actionProgress)
	local character = plr.Character or plr.CharacterAdded:Wait()
	local head = character:FindFirstChild("Head")
	if not head then return end

	RemoveGetupTimerLabel(head)
	local _, label = CreateGetupTimerLabel(head)

	local lastRealValue = actionProgress.Value
	local lastRealTime = tick()
	local lastUpdateTime = 0
	local _sound = nil
	local _soundPlaying = false

	-- Watcher directo: destruye el sonido INMEDIATAMENTE cuando ragdoll cesa
	local _ragdollWatcher
	_ragdollWatcher = ragdoll.Changed:Connect(function(v)
		if not v then
			if _sound then
				pcall(function() _sound:Stop(); _sound:Destroy() end)
				_sound = nil
			end
			_soundPlaying = false
			if _ragdollWatcher then
				_ragdollWatcher:Disconnect()
				_ragdollWatcher = nil
			end
		end
	end)

	GetupConnections[plr] = RunService.PreRender:Connect(function()
		local gSettings = Settings.GadgetSettings.ProgressSettings.GetupTimer
		local currentTime = tick()

		-- Verificar ragdoll ANTES del rate-limit para reacción inmediata
		if not ragdoll.Value then
			RemoveGetupTimerLabel(head)
			removeBottomRightUI(plr)
			if _sound then
				pcall(function() _sound:Stop(); _sound:Destroy() end)
				_sound = nil
			end
			_soundPlaying = false
			if _ragdollWatcher then _ragdollWatcher:Disconnect(); _ragdollWatcher = nil end
			if GetupConnections[plr] then
				GetupConnections[plr]:Disconnect()
				GetupConnections[plr] = nil
			end
			return
		end

		if currentTime - lastUpdateTime < gSettings.UpdateRate then return end
		lastUpdateTime = currentTime

		local realValue = actionProgress.Value

		if realValue ~= lastRealValue then
			lastRealValue = realValue
			lastRealTime = currentTime
		end

		local displayValue = realValue
		if gSettings.SmoothMode then
			local elapsed = currentTime - lastRealTime
			displayValue = math.min(1, realValue + (elapsed / c))
		end

		local secondsLeft = (1 - displayValue) * c
		if secondsLeft < 0 then
			RemoveGetupTimerLabel(head)
			removeBottomRightUI(plr)
			if _sound then
				pcall(function() _sound:Stop(); _sound:Destroy() end)
				_sound = nil
			end
			_soundPlaying = false
			if GetupConnections[plr] then
				GetupConnections[plr]:Disconnect()
				GetupConnections[plr] = nil
			end
		else
			if not gSettings.Enabled then
				label.Text = ""
			else
				local timerText = string.format("%.3f", secondsLeft)
				if label.Text ~= timerText then label.Text = timerText end
				local timerColor = secondsLeft <= gSettings.WhenToHit and gSettings.HitColor or gSettings.NotHitColor
				if label.TextColor3 ~= timerColor then label.TextColor3 = timerColor end
			end

			-- Sonido GetUp (solo si está activado desde Gadget Customization)
			if gSettings.SoundEnabled then
				if secondsLeft <= gSettings.SoundSecondsLeft and not _soundPlaying then
					_soundPlaying = true
					_sound = Instance.new("Sound")
					_sound.SoundId = "rbxassetid://12222005"
					_sound.Looped = true
					_sound.Volume = 1
					_sound.Parent = head
					_sound:Play()
				elseif secondsLeft > gSettings.SoundSecondsLeft and _soundPlaying then
					_soundPlaying = false
					if _sound then
						pcall(function() _sound:Stop(); _sound:Destroy() end)
						_sound = nil
					end
				end
			else
				-- Si se desactivó el sonido mientras sonaba, pararlo de inmediato
				if _sound then
					pcall(function() _sound:Stop(); _sound:Destroy() end)
					_sound = nil
				end
				_soundPlaying = false
			end

			updateBottomRightUI(plr, displayValue)
		end
	end)
end

function setupRagdollMonitoring(plr)
	local tempStats = plr:FindFirstChild("TempPlayerStatsModule")
	if not tempStats then
		return
	end

	local ragdoll = tempStats:FindFirstChild("Ragdoll")
	if not ragdoll then
		return
	end

	ConnectionManager:AddPerPlayer(
		plr,
		"RagdollMonitor",
		ragdoll.Changed:Connect(function(newValue)
			if not RopeHelperSettings.Enabled or not RopeHelperSettings.AutoRopeOnHit then
				return
			end

			if newValue then
				local myChar = player.Character
				if not myChar or not myChar:FindFirstChild("BeastPowers") then
					return
				end

				local myHrp = myChar:FindFirstChild("HumanoidRootPart")
				local targetHrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")

				if myHrp and targetHrp then
					local distance = (myHrp.Position - targetHrp.Position).Magnitude
					if distance <= RopeHelperSettings.MaxDistance then
						AutoRopePlayer(plr)
					end
				end
			end
		end)
	)
end
function onRagdollChanged(plr)
	local tempStats = plr:WaitForChild("TempPlayerStatsModule")
	local ragdoll = tempStats:WaitForChild("Ragdoll")
	local actionProgress = tempStats:WaitForChild("ActionProgress")

	if ragdoll.Value then
		startRagdollCountdown(plr, ragdoll, actionProgress)
		if not table.find(HitPlayers, plr) then
			table.insert(HitPlayers, plr)
		end
		updateUIPositions()
	end

	ragdoll.Changed:Connect(function()
		if ragdoll.Value then
			startRagdollCountdown(plr, ragdoll, actionProgress)
			if not table.find(HitPlayers, plr) then
				table.insert(HitPlayers, plr)
			end
			updateUIPositions()
			if RopeHelperSettings.AutoRopeOnHit and RopeHelperSettings.Enabled then
				AutoRopePlayer(plr)
			end
		else
			local character = plr.Character
			if character then
				RemoveGetupTimerLabel(character:FindFirstChild("Head"))
			end
			removeBottomRightUI(plr)
			local index = table.find(HitPlayers, plr)
			if index then
				table.remove(HitPlayers, index)
			end
			updateUIPositions()
			if GetupConnections[plr] then
				GetupConnections[plr]:Disconnect()
				GetupConnections[plr] = nil
			end
		end
	end)
end

function isDoorLocked(door)
	local trigger = door:FindFirstChild("DoorTrigger")
	if trigger then
		local actionSign = trigger:FindFirstChild("ActionSign")
		if actionSign then
			return actionSign.Value ~= 11
		end
	end
	return true
end

function isExitOpen(exit)
	local exitTrigger = exit:FindFirstChild("ExitDoorTrigger")
	if exitTrigger then
		return false
	end
	return true
end

function updateUIforPC(Pc, objectType, progress, timeRemaining, force)
	-- Puertas, salidas y PCs: si progreso, tiempo y nombre son iguales al ultimo dibujado no se toca la UI
	-- (antes se redibujaban TODAS en cada tick aunque no hubiera cambiado nada)
	local doorState
	if objectType == "door" then
		doorState = objectProgress.doors[Pc]
	elseif objectType == "exit" then
		doorState = objectProgress.exits[Pc]
	elseif objectType == "computer" then
		doorState = objectProgress.computers[Pc]
	end
	if
		doorState
		and not force
		and doorState.rp == progress
		and doorState.rt == timeRemaining
		and doorState.rn == doorState.playerName
	then
		return
	end

	local rawProgress = progress
	local gui = Pc:FindFirstChild("BillboardGui")
	if not gui then
		return
	end

	local ProgressBox = gui:FindFirstChild("ProgressBox")
	local ProgressFill = ProgressBox and ProgressBox:FindFirstChild("ProgressFill")
	local PercentageBox = gui:FindFirstChild("PercentageBox")
	local PlayerNameLabel = gui:FindFirstChild("PlayerNameLabel")

	if not ProgressBox or not ProgressFill or not PercentageBox then
		return
	end

	progress = math.clamp(progress or 0, 0, 1)

	local s
	local data
	if objectType == "computer" then
		s = Settings.GadgetSettings.ProgressSettings.PcProgress
		data = objectProgress.computers[Pc]
	elseif objectType == "exit" then
		s = Settings.GadgetSettings.ProgressSettings.ExitProgress
		data = objectProgress.exits[Pc]
	elseif objectType == "door" then
		s = Settings.GadgetSettings.ProgressSettings.DoorProgress
		data = objectProgress.doors[Pc]
	end

	if not s then
		return
	end

	if gui.Enabled ~= s.Enabled then
		gui.Enabled = s.Enabled
	end
	if s.Enabled then
		local bgTransparency = s.BackgroundTransparancy or 0.4
		local fillTransparency = s.ProgressTransparancy or 0.1
		if ProgressBox.BackgroundColor3 ~= s.BackgroundColor then ProgressBox.BackgroundColor3 = s.BackgroundColor end
		if ProgressBox.BackgroundTransparency ~= bgTransparency then ProgressBox.BackgroundTransparency = bgTransparency end
		if ProgressFill.BackgroundColor3 ~= s.ProgressFill then ProgressFill.BackgroundColor3 = s.ProgressFill end
		if ProgressFill.BackgroundTransparency ~= fillTransparency then ProgressFill.BackgroundTransparency = fillTransparency end
		if PercentageBox.TextColor3 ~= s.TextColor then PercentageBox.TextColor3 = s.TextColor end

		local percentageText = string.format("%.1f%%", progress * 100)
		local displayText = percentageText
		if s.DisplaySeconds and timeRemaining and timeRemaining > 0 then
			displayText = percentageText .. " | " .. string.format("%.3fs", timeRemaining)
		end
		if PercentageBox.Text ~= displayText then PercentageBox.Text = displayText end

		if PlayerNameLabel and data and objectType ~= "computer" and s.DisplayOpener then
			local playerText = (data.playerName and data.playerName ~= "") and data.playerName or ""
			if PlayerNameLabel.Text ~= playerText then PlayerNameLabel.Text = playerText end
			if playerText ~= "" and PlayerNameLabel.TextColor3 ~= s.OpenerTextColor then
				PlayerNameLabel.TextColor3 = s.OpenerTextColor
			end
		end
	end

	if ProgressFill.Size.X.Scale ~= progress then
		ProgressFill.Size = UDim2.new(progress, 0, 1, 0)
	end

	if doorState then
		doorState.rp = rawProgress
		doorState.rt = timeRemaining
		doorState.rn = doorState.playerName
	end
end

function updateprogresstracker(object, objectType, progress, timeRemaining, force)
	if objectType == "computer" then
		if objectProgress.computers[object] then
			objectProgress.computers[object].progress = progress
			objectProgress.computers[object].timeRemaining = timeRemaining
		end
	elseif objectType == "exit" then
		if objectProgress.exits[object] then
			objectProgress.exits[object].progress = progress
			objectProgress.exits[object].timeRemaining = timeRemaining
		end
	elseif objectType == "door" then
		if objectProgress.doors[object] then
			objectProgress.doors[object].progress = progress
			objectProgress.doors[object].timeRemaining = timeRemaining
		end
	end

	updateUIforPC(object, objectType, progress, timeRemaining, force)
end

function checkDoorAndExitStates()
	-- (El estado de las puertas ahora se resuelve en el Heartbeat con una sola llamada a isDoorLocked por puerta)
	for exit, data in pairs(objectProgress.exits) do
		if exit and exit.Parent then
			if data.progress >= 1 then
				data.timeRemaining = nil
				updateprogresstracker(exit, "exit", 1, nil)
				continue
			end

			local exitTrigger = exit:FindFirstChild("ExitDoorTrigger") or exit:FindFirstChild("Trigger")
			local isOpen = exitTrigger == nil

			if data.playerName == "" then
				local newProgress = isOpen and 1 or 0
				if newProgress == 1 or data.progress ~= newProgress then
					data.progress = newProgress
					data.timeRemaining = nil
					updateprogresstracker(exit, "exit", newProgress, nil)
				end
			end
		end
	end
end
function createuiforpc(Pc, objectType)
	local existingUI = Pc:FindFirstChild("BillboardGui")
	if existingUI then
		existingUI:Destroy()
	end

	local enabled = false
	if objectType == "computer" then
		enabled = Settings.GadgetSettings.ProgressSettings.PcProgress.Enabled
	elseif objectType == "exit" then
		enabled = Settings.GadgetSettings.ProgressSettings.ExitProgress.Enabled
	elseif objectType == "door" then
		enabled = Settings.GadgetSettings.ProgressSettings.DoorProgress.Enabled
	end

	local BillboardGui = Instance.new("BillboardGui")
	local size, studsOffset

	if objectType == "computer" then
		size = UDim2.new(25, 0, 25, 0)
		studsOffset = Vector3.new(0, 13, 0)

		local ProgressBox = Instance.new("Frame")
		local ProgressFill = Instance.new("Frame")
		local PercentageBox = Instance.new("TextLabel")
		local PlayerNameLabel = Instance.new("TextLabel")

		BillboardGui.Name = "BillboardGui"
		BillboardGui.Parent = Pc
		BillboardGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		BillboardGui.Active = true
		BillboardGui.AlwaysOnTop = true
		BillboardGui.LightInfluence = 1
		BillboardGui.Size = size
		BillboardGui.StudsOffset = studsOffset
		BillboardGui.Enabled = enabled

		ProgressBox.Name = "ProgressBox"
		ProgressBox.Parent = BillboardGui
		ProgressBox.AnchorPoint = Vector2.new(0.5, 0)
		ProgressBox.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
		ProgressBox.BackgroundTransparency = 0.4
		ProgressBox.BorderSizePixel = 0
		ProgressBox.Position = UDim2.new(0.5, 0, 0.94, 0)
		ProgressBox.Size = UDim2.new(0.5, 0, 0.04, 0)
		ProgressBox.SizeConstraint = Enum.SizeConstraint.RelativeYY

		ProgressFill.Name = "ProgressFill"
		ProgressFill.Parent = ProgressBox
		ProgressFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		ProgressFill.BackgroundTransparency = 0.1
		ProgressFill.BorderSizePixel = 0
		ProgressFill.Size = UDim2.new(0, 0, 1, 0)
		ProgressFill.ZIndex = 2

		PercentageBox.Name = "PercentageBox"
		PercentageBox.Parent = BillboardGui
		PercentageBox.AnchorPoint = Vector2.new(0.5, 0)
		PercentageBox.BackgroundTransparency = 1
		PercentageBox.Position = UDim2.new(0.5, 0, 0.89, 0)
		PercentageBox.Size = UDim2.new(0.5, 0, 0.04, 0)
		PercentageBox.SizeConstraint = Enum.SizeConstraint.RelativeYY
		PercentageBox.Text = "0.000%"
		PercentageBox.TextColor3 = Color3.fromRGB(255, 255, 255)
		PercentageBox.TextScaled = true

		PlayerNameLabel.Name = "PlayerNameLabel"
		PlayerNameLabel.Parent = BillboardGui
		PlayerNameLabel.AnchorPoint = Vector2.new(0.5, 0)
		PlayerNameLabel.BackgroundTransparency = 1
		PlayerNameLabel.Position = UDim2.new(0.5, 0, 0.84, 0)
		PlayerNameLabel.Size = UDim2.new(0.5, 0, 0.04, 0)
		PlayerNameLabel.SizeConstraint = Enum.SizeConstraint.RelativeYY
		PlayerNameLabel.Text = ""
		PlayerNameLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
		PlayerNameLabel.TextScaled = true
		PlayerNameLabel.TextStrokeTransparency = 0.5
	elseif objectType == "exit" then
		size = UDim2.new(25, 0, 25, 0)
		studsOffset = Vector3.new(0, 10, 0)

		local ProgressBox = Instance.new("Frame")
		local ProgressFill = Instance.new("Frame")
		local PercentageBox = Instance.new("TextLabel")
		local PlayerNameLabel = Instance.new("TextLabel")

		BillboardGui.Name = "BillboardGui"
		BillboardGui.Parent = Pc
		BillboardGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		BillboardGui.Active = true
		BillboardGui.AlwaysOnTop = true
		BillboardGui.LightInfluence = 1
		BillboardGui.Size = size
		BillboardGui.StudsOffset = studsOffset
		BillboardGui.Enabled = enabled

		ProgressBox.Name = "ProgressBox"
		ProgressBox.Parent = BillboardGui
		ProgressBox.AnchorPoint = Vector2.new(0.5, 0)
		ProgressBox.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
		ProgressBox.BackgroundTransparency = 0.4
		ProgressBox.BorderSizePixel = 0
		ProgressBox.Position = UDim2.new(0.5, 0, 0.94, 0)
		ProgressBox.Size = UDim2.new(0.5, 0, 0.04, 0)
		ProgressBox.SizeConstraint = Enum.SizeConstraint.RelativeYY

		ProgressFill.Name = "ProgressFill"
		ProgressFill.Parent = ProgressBox
		ProgressFill.BackgroundColor3 = Color3.fromRGB(85, 255, 127)
		ProgressFill.BackgroundTransparency = 0.1
		ProgressFill.BorderSizePixel = 0
		ProgressFill.Size = UDim2.new(0, 0, 1, 0)
		ProgressFill.ZIndex = 2

		PercentageBox.Name = "PercentageBox"
		PercentageBox.Parent = BillboardGui
		PercentageBox.AnchorPoint = Vector2.new(0.5, 0)
		PercentageBox.BackgroundTransparency = 1
		PercentageBox.Position = UDim2.new(0.5, 0, 0.89, 0)
		PercentageBox.Size = UDim2.new(0.5, 0, 0.04, 0)
		PercentageBox.SizeConstraint = Enum.SizeConstraint.RelativeYY
		PercentageBox.Text = "0.000%"
		PercentageBox.TextColor3 = Color3.fromRGB(85, 255, 127)
		PercentageBox.TextScaled = true

		PlayerNameLabel.Name = "PlayerNameLabel"
		PlayerNameLabel.Parent = BillboardGui
		PlayerNameLabel.AnchorPoint = Vector2.new(0.5, 0)
		PlayerNameLabel.BackgroundTransparency = 1
		PlayerNameLabel.Position = UDim2.new(0.5, 0, 0.84, 0)
		PlayerNameLabel.Size = UDim2.new(0.5, 0, 0.04, 0)
		PlayerNameLabel.SizeConstraint = Enum.SizeConstraint.RelativeYY
		PlayerNameLabel.Text = ""
		PlayerNameLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
		PlayerNameLabel.TextScaled = true
		PlayerNameLabel.TextStrokeTransparency = 0.5
	elseif objectType == "door" then
		size = UDim2.new(10, 0, 10, 0)
		studsOffset = Vector3.new(0, 0, 0)

		local ProgressBox = Instance.new("Frame")
		local ProgressFill = Instance.new("Frame")
		local PercentageBox = Instance.new("TextLabel")
		local PlayerNameLabel = Instance.new("TextLabel")

		BillboardGui.Name = "BillboardGui"
		BillboardGui.Parent = Pc
		BillboardGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		BillboardGui.Active = true
		BillboardGui.AlwaysOnTop = true
		BillboardGui.LightInfluence = 1
		BillboardGui.Size = size
		BillboardGui.StudsOffset = studsOffset
		BillboardGui.Enabled = enabled

		ProgressBox.Name = "ProgressBox"
		ProgressBox.Parent = BillboardGui
		ProgressBox.AnchorPoint = Vector2.new(0.5, 0)
		ProgressBox.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
		ProgressBox.BackgroundTransparency = 0.4
		ProgressBox.BorderSizePixel = 0
		ProgressBox.Position = UDim2.new(0.5, 0, 0.6, 0)
		ProgressBox.Size = UDim2.new(0.7, 0, 0.08, 0)
		ProgressBox.SizeConstraint = Enum.SizeConstraint.RelativeYY

		ProgressFill.Name = "ProgressFill"
		ProgressFill.Parent = ProgressBox
		ProgressFill.BackgroundColor3 = Color3.fromRGB(133, 88, 0)
		ProgressFill.BackgroundTransparency = 0.1
		ProgressFill.BorderSizePixel = 0
		ProgressFill.Size = UDim2.new(0, 0, 1, 0)
		ProgressFill.ZIndex = 2

		PercentageBox.Name = "PercentageBox"
		PercentageBox.Parent = BillboardGui
		PercentageBox.AnchorPoint = Vector2.new(0.5, 0)
		PercentageBox.BackgroundTransparency = 1
		PercentageBox.Position = UDim2.new(0.5, 0, 0.45, 0)
		PercentageBox.Size = UDim2.new(0.7, 0, 0.1, 0)
		PercentageBox.SizeConstraint = Enum.SizeConstraint.RelativeYY
		PercentageBox.Text = "0.000%"
		PercentageBox.TextColor3 = Color3.fromRGB(133, 88, 0)
		PercentageBox.TextScaled = true

		PlayerNameLabel.Name = "PlayerNameLabel"
		PlayerNameLabel.Parent = BillboardGui
		PlayerNameLabel.AnchorPoint = Vector2.new(0.5, 0)
		PlayerNameLabel.BackgroundTransparency = 1
		PlayerNameLabel.Position = UDim2.new(0.5, 0, 0.3, 0)
		PlayerNameLabel.Size = UDim2.new(0.7, 0, 0.12, 0)
		PlayerNameLabel.SizeConstraint = Enum.SizeConstraint.RelativeYY
		PlayerNameLabel.Text = ""
		PlayerNameLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
		PlayerNameLabel.TextScaled = true
		PlayerNameLabel.TextStrokeTransparency = 0.5
	end
end

function isValidDoorOrExit(obj)
	if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
		return false
	end
	if obj:IsA("BasePart") then
		return true
	end
	if obj:IsA("Model") then
		-- Busca solo la primera pieza necesaria; GetDescendants() creaba una tabla
		-- completa por cada modelo candidato durante el escaneo del mapa.
		return obj:FindFirstChildWhichIsA("BasePart", true) ~= nil
	end
	return false
end

function cleanupAllProgressUIs()
	for computer, data in pairs(objectProgress.computers) do
		local billboard = computer:FindFirstChild("BillboardGui")
		if billboard then
			billboard:Destroy()
		end
	end

	for door, data in pairs(objectProgress.doors) do
		local billboard = door:FindFirstChild("BillboardGui")
		if billboard then
			billboard:Destroy()
		end
	end

	for exit, data in pairs(objectProgress.exits) do
		local billboard = exit:FindFirstChild("BillboardGui")
		if billboard then
			billboard:Destroy()
		end
	end
end

function determinestuff()
	cleanupAllProgressUIs()

	computers = {}
	exits = {}
	doors = {}
	objectProgress = {
		computers = {},
		doors = {},
		exits = {},
	}

	local currentMap = getmap()
	if currentMap and currentMap.Parent then
		-- Los objetos de progreso pertenecen al mapa actual: no recorrer lobby,
		-- personajes y otros descendientes ajenos dentro de todo Workspace.
		for _, v in ipairs(currentMap:GetDescendants()) do
			local name = v.Name:lower()
			if not string.find(name, "trigger") then
				if string.find(name, "computertable") then
					if isValidDoorOrExit(v) then
						table.insert(computers, v)
						objectProgress.computers[v] = {
							progress = 0,
							playerName = "",
							hackerCount = 0,
							timeRemaining = nil,
						}
						createuiforpc(v, "computer")
						updateprogresstracker(v, "computer", 0, nil)
					end
				elseif string.find(name, "exitdoor") then
					if isValidDoorOrExit(v) then
						table.insert(exits, v)
						objectProgress.exits[v] = {
							progress = 0,
							playerName = "",
							lastProgress = 0,
							lastUpdateTime = tick(),
							progressVelocity = 0,
							timeRemaining = nil,
						}
						createuiforpc(v, "exit")
						updateprogresstracker(v, "exit", 0, nil)
					end
				elseif (name == "singledoor" or name == "doubledoor") and isValidDoorOrExit(v) then
					table.insert(doors, v)
					objectProgress.doors[v] = {
						progress = 0,
						playerName = "",
						lastProgress = 0,
						lastUpdateTime = tick(),
						progressVelocity = 0,
						timeRemaining = nil,
					}
					createuiforpc(v, "door")
					updateprogresstracker(v, "door", 0, nil)
				end
			end
		end
	end
end

function calculateTimeRemaining(object, objectType, progress, deltaTime, data)
	if progress <= 0 or progress >= 1 then
		return nil
	end

	local currentTime = tick()

	if objectType == "computer" then
		local hackerCount = data.hackerCount or 1
		if hackerCount < 1 then
			hackerCount = 1
		end

		local remainingProgress = 1 - progress
		local timeRemaining = (remainingProgress * 50) / hackerCount

		return timeRemaining
	elseif objectType == "door" then
		local deltaProgress = progress - data.lastProgress
		local timeSinceLastUpdate = currentTime - data.lastUpdateTime

		if deltaProgress > 0 and timeSinceLastUpdate > 0 then
			local progressPerSecond = deltaProgress / timeSinceLastUpdate
			local remainingProgress = 1 - progress
			return remainingProgress / progressPerSecond
		end

		local beast = GetBeast()
		local isBeastOpening = false
		if beast and data.playerName ~= "" then
			isBeastOpening = (data.playerName == beast.Name)
		end

		local totalTime = isBeastOpening and 1 or 1.5
		return (1 - progress) * totalTime
	elseif objectType == "exit" then
		return (1 - progress) * 11
	end

	return nil
end

function updateObjectUI(object, progress, playerName, objectType, deltaTime)
	local data
	if objectType == "computer" then
		data = objectProgress.computers[object]
	elseif objectType == "door" then
		data = objectProgress.doors[object]
	elseif objectType == "exit" then
		data = objectProgress.exits[object]
	end

	if not data then
		return
	end

	local timeRemaining = calculateTimeRemaining(object, objectType, progress, deltaTime, data)

	data.progress = progress
	data.playerName = playerName
	data.timeRemaining = timeRemaining
	data.lastProgress = progress
	data.lastUpdateTime = tick()

	updateprogresstracker(object, objectType, progress, timeRemaining)
end

function maintainObjectUIs(onlyChanged)
	for computer, data in pairs(objectProgress.computers) do
		if computer.Parent then
			local timeRemaining = calculateTimeRemaining(computer, "computer", data.progress, 0, data)
			data.timeRemaining = timeRemaining
			updateprogresstracker(computer, "computer", data.progress, timeRemaining, not onlyChanged)
		end
	end

	for door, data in pairs(objectProgress.doors) do
		if door.Parent then
			updateprogresstracker(door, "door", data.progress, data.timeRemaining, not onlyChanged)
		end
	end

	for exit, data in pairs(objectProgress.exits) do
		if exit.Parent then
			updateprogresstracker(exit, "exit", data.progress, data.timeRemaining, not onlyChanged)
		end
	end
end

_doorForceAcc = 0
_ptAcc = 0
progresstrackerconnection = RunService.Heartbeat:Connect(function(frameDt)
	-- Limitado a ~20 veces por segundo (antes corria en cada frame); se acumula el tiempo para no alterar los calculos
	_ptAcc = _ptAcc + frameDt
	if _ptAcc < 1 / 20 then
		return
	end
	local deltaTime = _ptAcc
	_ptAcc = 0

	local progressSettings = Settings.GadgetSettings.ProgressSettings
	local trackComputers = progressSettings.PcProgress.Enabled
	local trackDoors = progressSettings.DoorProgress.Enabled
	local trackExits = progressSettings.ExitProgress.Enabled

	-- Los tres trackers empiezan apagados: no hacer busquedas ni calcular distancias
	-- en segundo plano hasta que el jugador active al menos uno.
	if not trackComputers and not trackDoors and not trackExits then
		return
	end

	local activeObjects = {
		computers = {},
		doors = {},
		exits = {},
	}

	local computerHackers = {}
	if trackComputers then
		for _, computer in pairs(computers) do
			computerHackers[computer] = 0
		end
	end

	-- Un solo recorrido de jugadores por tick: antes se repetian dos veces
	-- las mismas busquedas de Character, HRP y TempPlayerStatsModule.
	for _, localPlayer in ipairs(Players:GetPlayers()) do
		local character = localPlayer.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		if not hrp then
			continue
		end

		local stats = localPlayer:FindFirstChild("TempPlayerStatsModule")
		if not stats then
			continue
		end

		local progressVal = stats:FindFirstChild("ActionProgress")
		local ragdollVal = stats:FindFirstChild("Ragdoll")
		local animVal = stats:FindFirstChild("CurrentAnimation")

		local progress = progressVal and progressVal.Value or 0
		if progress == 0 or (ragdollVal and ragdollVal.Value) then
			continue
		end

		local animation = animVal and animVal.Value or ""
		local playerPosition = hrp.Position

		if trackComputers and animation == "Typing" then
			local nearestComputer, distance = findNearestObject(playerPosition, computers)
			if nearestComputer and distance < 15 then
				computerHackers[nearestComputer] = (computerHackers[nearestComputer] or 0) + 1
				updateObjectUI(nearestComputer, progress, localPlayer.Name, "computer", deltaTime)
				activeObjects.computers[nearestComputer] = true
			end
		end

		if trackDoors then
			local nearestDoor, doorDistance = findNearestObject(playerPosition, doors)
			if nearestDoor and doorDistance < 8 then
				local doorData = objectProgress.doors[nearestDoor]
				if doorData and progress > 0 then
					updateObjectUI(nearestDoor, progress, localPlayer.Name, "door", deltaTime)
					activeObjects.doors[nearestDoor] = true
				end
			end
		end

		if trackExits then
			local nearestExit, exitDistance = findNearestObject(playerPosition, exits)
			if nearestExit and exitDistance < 20 then
				local exitData = objectProgress.exits[nearestExit]
				if exitData and progress > 0 and exitData.progress < 1 then
					updateObjectUI(nearestExit, progress, localPlayer.Name, "exit", deltaTime)
					activeObjects.exits[nearestExit] = true
				end
			end
		end
	end

	if trackComputers then
		for computer, count in pairs(computerHackers) do
			if objectProgress.computers[computer] then
				objectProgress.computers[computer].hackerCount = count
			end
		end

		for computer, data in pairs(objectProgress.computers) do
			if not activeObjects.computers[computer] then
				data.playerName = ""
				data.hackerCount = 0
			end
		end
	end

	if trackDoors then
		for door, data in pairs(objectProgress.doors) do
			if not activeObjects.doors[door] and door.Parent then
				if data.playerName ~= "" then
					data.playerName = ""
				end
				-- una sola consulta de isDoorLocked por puerta (antes eran hasta 3 por tick)
				if isDoorLocked(door) then
					if data.progress ~= 0 then
						data.progress = 0
						data.timeRemaining = nil
					end
				else
					data.progress = 1
				end
			end
		end
	end

	if trackExits then
		for exit, data in pairs(objectProgress.exits) do
			if not activeObjects.exits[exit] then
				if data.playerName ~= "" then
					data.playerName = ""
					data.timeRemaining = nil
					updateprogresstracker(exit, "exit", data.progress, data.timeRemaining)
				end

				local exitIsOpen = isExitOpen(exit)
				if not exitIsOpen and data.progress > 0 and data.progress < 1 then
					data.progress = 0
					data.timeRemaining = nil
				elseif exitIsOpen and data.progress < 1 then
					data.progress = 1
					data.timeRemaining = nil
				end

				if data.progress >= 1 then
					updateprogresstracker(exit, "exit", 1, nil)
				end
			end
		end
	end

	-- Puertas, salidas y PCs solo se redibujan si cambiaron; cada 0.5s se fuerza un repaso completo por si cambio algun ajuste
	_doorForceAcc = _doorForceAcc + deltaTime
	local forceDoors = false
	if _doorForceAcc >= 0.5 then
		_doorForceAcc = 0
		forceDoors = true
	end
	maintainObjectUIs(not forceDoors)
	if trackExits then
		checkDoorAndExitStates()
	end
end)

function CreateWalkspeedUI(character)
	if WalkspeedUIs[character] then
		return
	end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "WalkspeedBillboard"
	billboard.Adornee = hrp
	billboard.AlwaysOnTop = true
	billboard.Size = UDim2.new(0, 100, 0, 25)
	billboard.StudsOffset = Vector3.new(0, 6, 0)
	billboard.MaxDistance = 1000
	billboard.Parent = character

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = Settings.GadgetSettings.OtherGadgets.WalkspeedDetector.TextColor
	label.TextTransparency = Settings.GadgetSettings.OtherGadgets.WalkspeedDetector.TextTransparency
	label.Font = Enum.Font.GothamBold
	label.TextScaled = false
	label.TextSize = 17
	label.Text = "0"
	label.Parent = billboard

	local stroke = Instance.new("UIStroke")
	stroke.Color = Settings.GadgetSettings.OtherGadgets.WalkspeedDetector.StrokeColor
	stroke.Thickness = 2
	stroke.Transparency = Settings.GadgetSettings.OtherGadgets.WalkspeedDetector.StrokeTransparency
	stroke.Parent = label

	WalkspeedUIs[character] = {
		Gui = billboard,
		Label = label,
		Stroke = stroke,
		LastText = nil,
	}
end

function RemoveWalkspeedUI(character)
	local ui = WalkspeedUIs[character]
	if ui then
		ui.Gui:Destroy()
		WalkspeedUIs[character] = nil
	end
end

function UpdateWalkspeedColors()
	for character, ui in pairs(WalkspeedUIs) do
		if ui and ui.Label and ui.Stroke then
			ui.Label.TextColor3 = Settings.GadgetSettings.OtherGadgets.WalkspeedDetector.TextColor
			ui.Label.TextTransparency = Settings.GadgetSettings.OtherGadgets.WalkspeedDetector.TextTransparency
			ui.Stroke.Color = Settings.GadgetSettings.OtherGadgets.WalkspeedDetector.StrokeColor
			ui.Stroke.Transparency = Settings.GadgetSettings.OtherGadgets.WalkspeedDetector.StrokeTransparency
		end
	end
end

local function SetWalkspeedText(character, text)
	local ui = WalkspeedUIs[character]
	if ui and ui.LastText ~= text then
		ui.LastText = text
		ui.Label.Text = text
	end
end

-- Basico: muestra el WalkSpeed del Humanoid (metodo del script Walkspeed Above Head).
-- Si el jugador esta quieto muestra 0.0.
function UpdateBasicSpeed(character, hrp)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		SetWalkspeedText(character, "0.0")
		return
	end

	if humanoid.MoveDirection.Magnitude > 0.1 then
		SetWalkspeedText(character, string.format("%.1f", humanoid.WalkSpeed))
	else
		SetWalkspeedText(character, "0.0")
	end
end

local walkspeedLastUpdate = 0
walkspeedConnection = nil

function StopWalkspeedLoop()
	if walkspeedConnection then
		walkspeedConnection:Disconnect()
		walkspeedConnection = nil
	end
end

function StartWalkspeedLoop()
	StopWalkspeedLoop()
	walkspeedConnection = RunService.Heartbeat:Connect(function()
	if not Settings.GadgetSettings.OtherGadgets.WalkspeedDetector.Enabled then
		return
	end

	local nowClock = os.clock()
	if nowClock - walkspeedLastUpdate < 0.05 then
		return
	end
	walkspeedLastUpdate = nowClock

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= player then
			local character = plr.Character
			if character then
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if hrp then
					local ui = WalkspeedUIs[character]
					if not ui then
						CreateWalkspeedUI(character)
						ui = WalkspeedUIs[character]
					end
					if ui then
						UpdateBasicSpeed(character, hrp)
					end
				end
			end
		end
	end
	end)
end

function UpdateHeadstartTimer(TimeRemaining)
	local ui = playergui:FindFirstChild("HeadstartTracker")
	local textlabel = ui and ui:FindFirstChild("Timer")
	local stroke = textlabel and textlabel:FindFirstChild("Stroke")
	local sets = Settings.GadgetSettings.OtherGadgets.HeadstartTracker

	if not ui then
		ui = Instance.new("ScreenGui")
		ui.Name = "HeadstartTracker"
		ui.Parent = playergui

		textlabel = Instance.new("TextLabel")
		textlabel.Parent = ui
		textlabel.Name = "Timer"
		textlabel.AnchorPoint = Vector2.new(0.5, 0.5)
		textlabel.Position = UDim2.fromScale(0.5, 0.75)
		textlabel.Size = UDim2.fromScale(0.25, 0.25)
		textlabel.BackgroundTransparency = 1
		textlabel.TextScaled = true
		textlabel.Text = ""
		textlabel.TextColor3 = sets.TextColor
		textlabel.TextTransparency = sets.TextTransparancy

		stroke = Instance.new("UIStroke")
		stroke.Name = "Stroke"
		stroke.Parent = textlabel
		stroke.Color = sets.StrokeColor
		stroke.Transparency = sets.StrokeTransparancy
	end

	if textlabel and stroke then
		textlabel.TextColor3 = sets.TextColor
		textlabel.TextTransparency = sets.TextTransparancy
		stroke.Color = sets.StrokeColor
		stroke.Transparency = sets.StrokeTransparancy

		if TimeRemaining then
			if sets.Enabled then
				textlabel.Text = string.format("%.3f", TimeRemaining)
			else
				textlabel.Text = ""
			end
		end
	end
end

function StopHeadstartTracking()
	local sets = Settings.GadgetSettings.OtherGadgets.HeadstartTracker
	if sets.TrackerConnection then
		sets.TrackerConnection:Disconnect()
		sets.TrackerConnection = nil
	end
	local ui = playergui:FindFirstChild("HeadstartTracker")
	if ui then
		ui:Destroy()
	end
end

function StartHeadstartTracking()
	if not Settings.GadgetSettings.OtherGadgets.HeadstartTracker.Enabled then
		return
	end

	StopHeadstartTracking()

	local sets = Settings.GadgetSettings.OtherGadgets.HeadstartTracker

	local ui = Instance.new("ScreenGui")
	ui.Name = "HeadstartTracker"
	ui.Parent = playergui

	local text = Instance.new("TextLabel")
	text.Parent = ui
	text.Name = "Timer"
	text.AnchorPoint = Vector2.new(0.5, 0.5)
	text.Position = UDim2.fromScale(0.5, 0.75)
	text.Size = UDim2.fromScale(0.25, 0.25)
	text.BackgroundTransparency = 1
	text.TextScaled = true
	text.Text = "15.000"
	text.TextColor3 = sets.TextColor
	text.TextTransparency = sets.TextTransparancy

	local stroke = Instance.new("UIStroke")
	stroke.Parent = text
	stroke.Color = sets.StrokeColor
	stroke.Transparency = sets.StrokeTransparancy

	local mytime = 15.5
	local textAcc = 0
	local lastShown = ""
	local myconnection
	myconnection = RunService.Heartbeat:Connect(function(deltaTime)
		if not sets.Enabled then
			StopHeadstartTracking()
			return
		end
		mytime = mytime - deltaTime
		if mytime <= 0 then
			StopHeadstartTracking()
			return
		end
		-- TextScaled recalcula el texto en cada cambio: se actualiza ~30 veces por segundo
		textAcc = textAcc + deltaTime
		if textAcc < 0.033 then
			return
		end
		textAcc = 0
		local str = string.format("%.3f", mytime)
		if str ~= lastShown then
			lastShown = str
			text.Text = str
		end
	end)
	sets.TrackerConnection = myconnection
end

function GetCurrentBoost()
	local ME = Players.LocalPlayer
	local MyChar = ME.Character
	if not MyChar then
		return 0, 0
	end

	local Humanoid = MyChar:FindFirstChild("Humanoid")
	if not Humanoid then
		return 0, 0
	end

	local WalkSpeed = Humanoid.WalkSpeed
	local Beast = MyChar:FindFirstChild("BeastPowers")

	if Beast then
		if WalkSpeed >= 20 and WalkSpeed <= 29 then
			return SpeedSettings.RunnerBoost, 0
		elseif WalkSpeed >= 15 and WalkSpeed <= 19 then
			return SpeedSettings.BeastBoost, SpeedSettings.BeastJumpPower
		elseif WalkSpeed >= 1 and WalkSpeed <= 6 then
			return SpeedSettings.FatigueBoost, SpeedSettings.BeastJumpPower
		end
	else
		if WalkSpeed >= 15 and WalkSpeed <= 18 then
			return SpeedSettings.SurvivorBoost, SpeedSettings.SurvivorJumpPower
		elseif WalkSpeed >= 6 and WalkSpeed <= 10 then
			return SpeedSettings.CrawlBoost, SpeedSettings.SurvivorJumpPower
		end
	end

	return 0, 0
end

function ResetSpeed()
	if SpeedSettings.Connection then
		SpeedSettings.Connection:Disconnect()
		SpeedSettings.Connection = nil
	end
end

function ApplySpeed()
	if not SpeedSettings.Enabled then
		return
	end
	if SpeedSettings.Connection then
		SpeedSettings.Connection:Disconnect()
	end

	local lastBrickCheck = 0
	SpeedSettings.Connection = RunService.Stepped:Connect(function(gameTime, deltaTime)
		local ME = Players.LocalPlayer
		if not ME then
			return
		end
		local MyChar = ME.Character
		if not MyChar then
			return
		end

		-- Busqueda recursiva: antes corria en cada frame, ahora 2 veces por segundo
		local brickNow = os.clock()
		if brickNow - lastBrickCheck >= 0.5 then
			lastBrickCheck = brickNow
			local camBrick = MyChar:FindFirstChild("CamBrick", true)
			if camBrick then
				camBrick:Destroy()
			end
		end

		if not SpeedSettings.Enabled then
			return
		end

		local Humanoid = MyChar:FindFirstChild("Humanoid")
		local HumanoidRootPart = MyChar:FindFirstChild("HumanoidRootPart")
		if not Humanoid or not HumanoidRootPart then
			return
		end

		local MoveDirection = Humanoid.MoveDirection

		if MoveDirection.Magnitude > 0 then
			local boost, jumpPower = GetCurrentBoost()

			if boost > 0 then
				HumanoidRootPart.CFrame = HumanoidRootPart.CFrame + (MoveDirection * boost * deltaTime)
			end

			if SpeedSettings.JumpPowerEnabled and jumpPower > 0 then
				Humanoid.JumpPower = jumpPower
				SpeedSettings.LastAppliedJP = jumpPower
			end
		end
	end)
end

-- ============================================================
-- CROSSHAIR (un solo cursor con tipo elegible: Normal / Danger)
-- Solo existe mientras el toggle esta activado; sin loops extra.
-- ============================================================
CursorCrosshair = { Gui = nil, Label = nil, Conn = nil }

function GetCrosshairColor()
	if CrosshairSettings.UseColor then
		return CrosshairSettings.Color
	end
	return Color3.fromRGB(255, 255, 255)
end

function GetCrosshairSize()
	local t = CrosshairSettings.Types[CrosshairSettings.Type]
	return t.Min + ((t.Slider - 1) / 99) * (t.Max - t.Min)
end

-- Resuelve una sola vez la imagen real de cada tipo (por si el ID es de un Decal). Se cachea.
function ResolveCrosshairImage(typeName)
	local t = CrosshairSettings.Types[typeName]
	if not t or t.Image or t.Resolving then
		return
	end
	t.Resolving = true
	task.spawn(function()
		local fallback = "rbxassetid://" .. t.DecalId
		local image = fallback
		local ok, objs = pcall(function()
			return game:GetObjects(fallback)
		end)
		if ok and objs and objs[1] and (objs[1]:IsA("Decal") or objs[1]:IsA("Texture")) then
			image = objs[1].Texture
		end
		t.Image = image
		t.Resolving = false
		if CursorCrosshair.Label and CrosshairSettings.Type == typeName then
			CursorCrosshair.Label.Image = image
		end
	end)
end

function CreateCrosshair()
	if CursorCrosshair.Conn then
		CursorCrosshair.Conn:Disconnect()
		CursorCrosshair.Conn = nil
	end
	if CursorCrosshair.Gui then
		CursorCrosshair.Gui:Destroy()
		CursorCrosshair.Gui = nil
		CursorCrosshair.Label = nil
	end

	local defaultCrosshair = playergui:FindFirstChild("CrosshairGUI")

	if not CrosshairSettings.Enabled then
		UserInputService.MouseIconEnabled = true
		if defaultCrosshair then
			defaultCrosshair.Enabled = true
		end
		return
	end

	if defaultCrosshair then
		defaultCrosshair.Enabled = false
	end

	local parent = (gethui and gethui()) or CoreGui
	local old = parent:FindFirstChild("CustomCursorGui")
	if old then
		old:Destroy()
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "CustomCursorGui"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 2147483647
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = parent

	local t = CrosshairSettings.Types[CrosshairSettings.Type]
	local size = GetCrosshairSize()

	local cursor = Instance.new("ImageLabel")
	cursor.Name = "Cursor"
	cursor.BackgroundTransparency = 1
	cursor.Image = t.Image or ("rbxassetid://" .. t.DecalId)
	cursor.ImageColor3 = GetCrosshairColor()
	cursor.Size = UDim2.fromOffset(size, size)
	cursor.AnchorPoint = Vector2.new(0.5, 0.5)
	cursor.ZIndex = 10
	cursor.Parent = gui

	CursorCrosshair.Gui = gui
	CursorCrosshair.Label = cursor
	ResolveCrosshairImage(CrosshairSettings.Type)

	CursorCrosshair.Conn = RunService.RenderStepped:Connect(function()
		if UserInputService.MouseIconEnabled then
			UserInputService.MouseIconEnabled = false
		end
		local ct = CrosshairSettings.Types[CrosshairSettings.Type]
		local pos = UserInputService:GetMouseLocation()
		cursor.Position = UDim2.fromOffset(pos.X + ct.OffsetX, pos.Y + ct.OffsetY)
	end)
end

-- Cambiar tamano o color solo reajusta el cursor, no lo vuelve a crear
function UpdateCrosshair()
	local label = CursorCrosshair.Label
	if label then
		local size = GetCrosshairSize()
		label.Size = UDim2.fromOffset(size, size)
		label.ImageColor3 = GetCrosshairColor()
	end
end

function SetCrosshairType(typeName)
	if not CrosshairSettings.Types[typeName] then
		return
	end
	CrosshairSettings.Type = typeName
	local t = CrosshairSettings.Types[typeName]
	-- La barra de Size muestra el valor guardado de este tipo
	if Options.CrosshairSize and Options.CrosshairSize.Value ~= t.Slider then
		Options.CrosshairSize:SetValue(t.Slider)
	end
	local label = CursorCrosshair.Label
	if label then
		label.Image = t.Image or ("rbxassetid://" .. t.DecalId)
		ResolveCrosshairImage(typeName)
		UpdateCrosshair()
	end
end

function FlopAction(actionName, inputState, inputObject)
	if not FlopSettings.Enabled then
		return Enum.ContextActionResult.Pass
	end

	if inputState == Enum.UserInputState.Begin then
		local MyChar = player.Character
		if not MyChar then
			return Enum.ContextActionResult.Pass
		end

		local HumanoidRootPart = MyChar:FindFirstChild("HumanoidRootPart")
		local tempStats = player:FindFirstChild("TempPlayerStatsModule")

		if not HumanoidRootPart or not tempStats then
			return Enum.ContextActionResult.Pass
		end

		local ragdoll = tempStats:FindFirstChild("Ragdoll")
		if not ragdoll or not ragdoll.Value then
			return Enum.ContextActionResult.Pass
		end

		local currentTime = time()
		if currentTime - FlopSettings.LastFlopTime >= FlopSettings.Delay then
			FlopSettings.LastFlopTime = currentTime

			local direction = HumanoidRootPart.CFrame.p - workspace.CurrentCamera.CFrame.p
			local flopVector = Vector3.new(
				direction.X * FlopSettings.XMultiplier,
				direction.Y * FlopSettings.YMultiplier,
				direction.Z * FlopSettings.ZMultiplier
			)

			local RemoteEvent = ReplicatedStorage:FindFirstChild("RemoteEvent")
			if RemoteEvent then
				RemoteEvent:FireServer("Flop", flopVector)
			end
		end
	end

	return Enum.ContextActionResult.Sink
end

function StartFlopHelper()
	local MyChar = player.Character
	if not MyChar then
		return
	end

	local Humanoid = MyChar:FindFirstChild("Humanoid")
	local tempStats = player:FindFirstChild("TempPlayerStatsModule")

	if not Humanoid or not tempStats then
		return
	end

	local ragdoll = tempStats:FindFirstChild("Ragdoll")

	if FlopSettings.FlopConnection then
		FlopSettings.FlopConnection:Disconnect()
	end

	local function updateFlopBind(isRagdolled)
		if isRagdolled and FlopSettings.Enabled then
			Humanoid:ChangeState(Enum.HumanoidStateType.Physics)
			Humanoid.JumpPower = 0
			player.CameraMinZoomDistance = 2
			task.wait()
			for _, v in pairs(Humanoid:GetPlayingAnimationTracks()) do
				v:AdjustSpeed(0)
			end
			ContextActionService:UnbindAction("Flop")
			ContextActionService:BindAction("Flop", FlopAction, true, Enum.KeyCode.Space, Enum.KeyCode.ButtonA)
			ContextActionService:SetTitle("Flop", "W")
		else
			Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
			Humanoid.JumpPower = 36
			player.CameraMinZoomDistance = 0.5
			ContextActionService:UnbindAction("Flop")
		end
	end

	if ragdoll then
		updateFlopBind(ragdoll.Value)
		FlopSettings.FlopConnection = ragdoll.Changed:Connect(updateFlopBind)
	end
end

function StopFlopHelper()
	if FlopSettings.FlopConnection then
		FlopSettings.FlopConnection:Disconnect()
		FlopSettings.FlopConnection = nil
	end
	ContextActionService:UnbindAction("Flop")

	local MyChar = player.Character
	if MyChar then
		local Humanoid = MyChar:FindFirstChild("Humanoid")
		if Humanoid then
			Humanoid.JumpPower = 36
		end
		player.CameraMinZoomDistance = 0.5
	end
end

-- Lista de personajes actuales (se arma una vez por tanda en vez de una vez por cada parte)
function GetCharacterList()
	local chars = {}
	for _, v in ipairs(Players:GetPlayers()) do
		local c = v.Character
		if c then
			chars[#chars + 1] = c
		end
	end
	return chars
end

function isPartOfPlayerCharacter(part, chars)
	chars = chars or GetCharacterList()
	for i = 1, #chars do
		if part:IsDescendantOf(chars[i]) then
			return true
		end
	end
	return false
end

-- Recorre workspace repartido en varios frames (antes todo ocurria en un solo frame = tiron al activar).
-- isActive() permite cancelar si el toggle se apaga a mitad del recorrido.
function ScanWorkspaceChunked(isActive, handler, root)
	task.spawn(function()
		local list = (root or workspace):GetDescendants()
		local chars = GetCharacterList()
		for i = 1, #list do
			if not isActive() then
				return
			end
			handler(list[i], chars)
			if i % 300 == 0 then
				task.wait()
				chars = GetCharacterList()
			end
		end
	end)
end

function isExcludedFromBarrier(part)
	local obj = part
	if
		obj.Name == "ComputerTable"
		or obj.Name == "ExitDoor"
		or obj.Name == "SingleDoor"
		or obj.Name == "DoubleDoor"
		or obj.Name == "VentBlock"
		or obj.Name == "InvisibleWall"
		or obj.Name == "OBSpawnPad"
		or obj.Name == "WindowBlock"
		or obj.Name == "FacilitySiren"
	then
		return true
	end
	return false
end

function EnableWallhops()
	-- Solo dentro del mapa actual (sea cual sea): el lobby y lo de fuera del mapa no se tocan.
	-- Recorre menos partes que todo workspace, asi que tambien es mas liviano.
	local themap = getmap()
	if not themap or not themap.Parent then
		return
	end
	ScanWorkspaceChunked(function()
		return WallhopSettings.Enabled
	end, function(part, chars)
		if
			part.Parent
			and part:IsA("Part")
			and part.Shape == Enum.PartType.Block
			and part.Transparency ~= 1
			and part.CanCollide
			and not isPartOfPlayerCharacter(part, chars)
			and not part:FindFirstChildOfClass("SelectionBox")
		then
			local selectionBox = Instance.new("SelectionBox")
			selectionBox.Color3 = Color3.fromRGB(255, 255, 255)
			selectionBox.LineThickness = 0.025
			selectionBox.Adornee = part
			selectionBox.Parent = part
			table.insert(WallhopSettings.SelectionBoxes, selectionBox)
		end
	end, themap)
end

function DisableWallhops()
	for _, selectionBox in ipairs(WallhopSettings.SelectionBoxes) do
		if selectionBox and selectionBox.Parent then
			selectionBox:Destroy()
		end
	end
	WallhopSettings.SelectionBoxes = {}
end

function EnableBarrierVisibility()
	ScanWorkspaceChunked(function()
		return BarrierSettings.Enabled
	end, function(part, chars)
		if
			part.Parent
			and part:IsA("BasePart")
			and part.Transparency == 1
			and not isPartOfPlayerCharacter(part, chars)
			and not isExcludedFromBarrier(part)
		then
			BarrierSettings.OriginalTransparencies[part] = part.Transparency
			part.Transparency = 0.5
			part.Color = Color3.fromRGB(255, 0, 0)
		end
	end)
end

function DisableBarrierVisibility()
	for part, originalTransparency in pairs(BarrierSettings.OriginalTransparencies) do
		if part and part.Parent then
			part.Transparency = originalTransparency
		end
	end
	BarrierSettings.OriginalTransparencies = {}
end

-- ============================================================
-- NO FOG (se mantiene actualizado como Black Fog, pero por eventos: sin bucles)
-- Si el juego o el mapa cambian la niebla, o crean una Atmosphere/Sky nueva, se vuelve a aplicar.
-- Solo escribe cuando el valor es distinto (no hay ciclos). Al apagarlo: 0 conexiones.
-- Con Boost Game activo la densidad sigue en 0 (Boost la restaura al soltarlo).
-- ============================================================
NF_ATM = {
	Color = Color3.fromRGB(0, 0, 0),
	Glare = 0,
	Haze = 10,
	Decay = Color3.fromRGB(0, 0, 0),
	Density = 0,
	Offset = 0,
}

function NoFog_ApplyAtmosphere(atm)
	for k, v in pairs(NF_ATM) do
		if atm[k] ~= v then
			atm[k] = v
		end
	end
end

function NoFog_ApplySky(sky)
	if sky.MoonAngularSize ~= 10 then
		sky.MoonAngularSize = 10
	end
	if sky.StarCount ~= 0 then
		sky.StarCount = 0
	end
end

-- Reaplicacion con freno: aunque el juego cambie la Atmosphere/Sky muy seguido (o otro efecto del
-- script pelee con este), se escribe como maximo cada 0.15 s en vez de en cada cambio.
NF_Pending = false
NF_Last = 0

function NoFog_Reapply()
	if NF_Pending or not FogSettings.Enabled then
		return
	end
	NF_Pending = true
	local function run()
		NF_Pending = false
		NF_Last = os.clock()
		if not FogSettings.Enabled then
			return
		end
		-- Con No Sky Visuals activo, el ya maneja la Atmosphere y el Sky: no se pelea con el
		if NoSkyVisuals and NoSkyVisuals.Saved then
			return
		end
		for _, c in ipairs(Lighting:GetChildren()) do
			if c:IsA("Atmosphere") then
				NoFog_ApplyAtmosphere(c)
			elseif c:IsA("Sky") then
				NoFog_ApplySky(c)
			end
		end
	end
	local w = 0.15 - (os.clock() - NF_Last)
	if w > 0 then
		task.delay(w, run)
	else
		task.defer(run)
	end
end

function NoFog_Track(inst)
	if inst:IsA("Atmosphere") then
		if not FogSettings.OriginalAtmosphere then
			FogSettings.OriginalAtmosphere = {
				Instance = inst,
				Color = inst.Color,
				Glare = inst.Glare,
				Haze = inst.Haze,
				Decay = inst.Decay,
				Density = RealAtmDensity(inst),
				Offset = inst.Offset,
			}
		end
		if not (NoSkyVisuals and NoSkyVisuals.Saved) then
			NoFog_ApplyAtmosphere(inst)
		end
		table.insert(FogSettings.Conns, inst.Changed:Connect(NoFog_Reapply))
	elseif inst:IsA("Sky") then
		if not FogSettings.OriginalSky then
			FogSettings.OriginalSky = {
				Instance = inst,
				MoonAngularSize = inst.MoonAngularSize,
				StarCount = inst.StarCount,
			}
		end
		if not (NoSkyVisuals and NoSkyVisuals.Saved) then
			NoFog_ApplySky(inst)
		end
		table.insert(FogSettings.Conns, inst.Changed:Connect(NoFog_Reapply))
	end
end

function NoFog_Disconnect()
	for i = #FogSettings.Conns, 1, -1 do
		FogSettings.Conns[i]:Disconnect()
		FogSettings.Conns[i] = nil
	end
end

function EnableNoFog()
	NoFog_Disconnect()
	for _, child in ipairs(Lighting:GetChildren()) do
		NoFog_Track(child)
	end
	table.insert(FogSettings.Conns, Lighting.ChildAdded:Connect(NoFog_Track))
end

function DisableNoFog()
	NoFog_Disconnect()

	local og = FogSettings.OriginalAtmosphere
	if og and og.Instance and og.Instance.Parent then
		local atmosphere = og.Instance
		atmosphere.Color = og.Color
		atmosphere.Glare = og.Glare
		atmosphere.Haze = og.Haze
		atmosphere.Decay = og.Decay
		atmosphere.Density = og.Density
		atmosphere.Offset = og.Offset
	end
	FogSettings.OriginalAtmosphere = nil

	local ogSky = FogSettings.OriginalSky
	if ogSky and ogSky.Instance and ogSky.Instance.Parent then
		ogSky.Instance.MoonAngularSize = ogSky.MoonAngularSize
		ogSky.Instance.StarCount = ogSky.StarCount
	end
	FogSettings.OriginalSky = nil

	-- Si Boost Game sigue activo, la niebla se queda en 0
	BoostKeepAtmosphere()
end

function DisableBushes()
	for i = #BushSettings.Cached, 1, -1 do
		local v = BushSettings.Cached[i]
		if v and v.Parent then
			v.Transparency = 0
		end
		table.remove(BushSettings.Cached, i)
	end
end

function EnableBushes()
	ScanWorkspaceChunked(function()
		return BushSettings.Enabled
	end, function(v)
		if v.Parent and v:IsA("BasePart") then
			if
				getIsTreeBush(v.Size)
				and v.Transparency == 0
				and v.CanCollide == false
				and v.Material == Enum.Material.Grass
			then
				v.Transparency = 1
				table.insert(BushSettings.Cached, v)
			end
		end
	end)
end

function DisableShadows()
	ShadowSettings.OriginalState = Lighting.GlobalShadows
	Lighting.GlobalShadows = false
end

function EnableShadows()
	Lighting.GlobalShadows = ShadowSettings.OriginalState
end

function trackPlayer(plr)
	local function applyEsp()
		local char = plr.Character
		if not char or not char:FindFirstChild("HumanoidRootPart") then
			return
		end

		if not Settings.EspSettings.PlayerEsp.Enabled then
			return
		end

		if Settings.EspSettings.PlayerEsp.UseSkeletonEsp then
			createSkeletonUI(char)
		else
			AddPlayerEsp(char)
		end

		if Settings.GadgetSettings.OtherGadgets.WalkspeedDetector.Enabled then
			CreateWalkspeedUI(char)
		end
	end

	local conn = plr.CharacterAdded:Connect(function(char)
		char:WaitForChild("HumanoidRootPart")
		task.wait(0.1)
		applyEsp()

		if plr == player and FlopSettings.Enabled then
			task.wait(0.5)
			StartFlopHelper()
		end
	end)

	if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
		task.wait(0.1)
		applyEsp()

		if plr == player and FlopSettings.Enabled then
			StartFlopHelper()
		end
	end

	PlayerConnections.EspConnections[plr] = conn
end

function untrackPlayer(plr)
	if plr.Character then
		removeSkeletonUI(plr.Character)
		RemovePlayerEsp(plr.Character)
		RemoveWalkspeedUI(plr.Character)
	end
	local conn = PlayerConnections.EspConnections[plr]
	if conn then
		conn:Disconnect()
		PlayerConnections.EspConnections[plr] = nil
	end
end

function CleanupMapEsp()
	StopPcEsp()
	StopTubeEsp()
	StopExitEsp()
end

function RopeNearestRagdolled(mousePosition)
	local nearestPlayer = nil
	local shortestDistance = math.huge

	for _, plr in pairs(Players:GetPlayers()) do
		if plr ~= player and plr.Character then
			local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
			local tempStats = plr:FindFirstChild("TempPlayerStatsModule")

			if hrp and tempStats then
				local ragdoll = tempStats:FindFirstChild("Ragdoll")
				if ragdoll and ragdoll.Value then
					local screenPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(hrp.Position)
					if onScreen then
						local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePosition).Magnitude
						if distance < shortestDistance and distance < 50 then
							shortestDistance = distance
							nearestPlayer = plr
						end
					end
				end
			end
		end
	end

	if nearestPlayer then
		local myChar = player.Character
		local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
		local targetHrp = nearestPlayer.Character and nearestPlayer.Character:FindFirstChild("HumanoidRootPart")

		if myHrp and targetHrp then
			local distance = (myHrp.Position - targetHrp.Position).Magnitude
			if distance <= RopeHelperSettings.MaxDistance then
				AutoRopePlayer(nearestPlayer)
			end
		end
	end
end
ConnectionManager:AddGlobal(
	"RopeHelperClick",
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if
			input.UserInputType == Enum.UserInputType.MouseButton2
			and RopeHelperSettings.ClickToRope
			and RopeHelperSettings.Enabled
		then
			local mousePos = UserInputService:GetMouseLocation()
			RopeNearestRagdolled(mousePos)
		end
	end)
)
conn2 = Players.PlayerRemoving:Connect(function(p)
	NameHiderSettings.CustomPlayers[p.Name] = nil
	for obj in pairs(NameHiderSettings.TextObjectCache) do
		replaceInObject(obj)
	end
end)

function formatChatMessage(msg, plr)
	if not NameHiderSettings.Enabled then
		return msg
	end
	local newName, _, _, tag, tagColor = getPlayerData(plr.Name)
	if not newName then
		return msg
	end
	local m = msg
	if tag and tagColor then
		local col = tagColor:gsub("#", "")
		m = string.format("<font color='#%s'>[%s]</font> %s", col, tag, m)
	end
	return m
end

gameactivechanged = game.ReplicatedStorage.IsGameActive.Changed:Connect(function()
	UpdatePlayerEsp()
	if game.ReplicatedStorage.IsGameActive.Value == true then
		task.wait(1)
		StopRunnerTimer()
		StartRunnerTimer()

		if Settings.EspSettings.PcEsp.Enabled then
			StartPcEsp()
		end
		if Settings.EspSettings.TubeEsp.Enabled then
			StartTubeEsp()
		end
		if Settings.EspSettings.ExitEsp.Enabled then
			StartExitEsp()
		end
		if Settings.EspSettings.DoorEsp.Enabled then
			DoorEsp()
		end
	end
end)

mapchanged = game.ReplicatedStorage.CurrentMap.Changed:Connect(function()
	cleanupAllProgressUIs()

	task.wait(2)

	StopRunnerTimer()
	StartRunnerTimer()

	if Settings.EspSettings.PcEsp.Enabled then
		StartPcEsp()
	end
	if Settings.EspSettings.TubeEsp.Enabled then
		StartTubeEsp()
	end
	if Settings.EspSettings.ExitEsp.Enabled then
		StartExitEsp()
	end
	if Settings.EspSettings.DoorEsp.Enabled then
		DoorEsp()
	end

	if BarrierSettings.Enabled then
		DisableBarrierVisibility()
		EnableBarrierVisibility()
	end

	if WallhopSettings.Enabled then
		DisableWallhops()
		EnableWallhops()
	end

	if BushSettings.Enabled then
		DisableBushes()
		EnableBushes()
	end

end)
if game.ReplicatedStorage.IsGameActive.Value == true then
	determinestuff()

	if Settings.EspSettings.PcEsp.Enabled then
		StartPcEsp()
	end
	if Settings.EspSettings.TubeEsp.Enabled then
		StartTubeEsp()
	end
	if Settings.EspSettings.ExitEsp.Enabled then
		StartExitEsp()
	end
	if Settings.EspSettings.DoorEsp.Enabled then
		DoorEsp()
	end
end

if getmap() then
	task.wait(2)
	determinestuff()
end

PlayerConnections.GameStartingConnection = game:GetService("ReplicatedStorage").GameStatus
	:GetPropertyChangedSignal("Value")
	:Connect(function()
		if game:GetService("ReplicatedStorage").GameStatus.Value == "GAME STARTING" then
			task.wait(2)
			CleanupMapEsp()
			if Settings.EspSettings.PcEsp.Enabled then
				StartPcEsp()
			end
			if Settings.EspSettings.TubeEsp.Enabled then
				StartTubeEsp()
			end
			if Settings.EspSettings.ExitEsp.Enabled then
				StartExitEsp()
			end
			if Settings.EspSettings.DoorEsp.Enabled then
				DoorEsp()
			end
			determinestuff()
		end

		if game:GetService("ReplicatedStorage").GameStatus.Value == "15 SEC HEAD START" then
			task.wait(0.5)
			-- El contador sale primero y el resto se reparte en varios frames
			-- para que no haya un pico de lag justo cuando empieza el headstart.
			StartHeadstartTracking()
			task.wait()
			if Settings.EspSettings.PcEsp.Enabled then
				StartPcEsp()
				task.wait()
			end
			if Settings.EspSettings.TubeEsp.Enabled then
				StartTubeEsp()
				task.wait()
			end
			if Settings.EspSettings.ExitEsp.Enabled then
				StartExitEsp()
				task.wait()
			end
			if Settings.EspSettings.DoorEsp.Enabled then
				DoorEsp()
				task.wait()
			end
		end
	end)

local PcEspToggle = Groupboxes.Visual.LeftGroupBox:AddToggle("PcEsp", {
	Text = "Computer ESP",
	Default = false,
	Callback = function(Value)
		Settings.EspSettings.PcEsp.Enabled = Value
		if Value then
			StartPcEsp()
		else
			StopPcEsp()
		end
	end,
})

local TubeEspToggle = Groupboxes.Visual.LeftGroupBox:AddToggle("TubeEsp", {
	Text = "Tube ESP",
	Default = false,
	Callback = function(Value)
		Settings.EspSettings.TubeEsp.Enabled = Value
		if Value then
			StartTubeEsp()
		else
			StopTubeEsp()
		end
	end,
})

local DoorEspToggle = Groupboxes.Visual.LeftGroupBox:AddToggle("DoorEsp", {
	Text = "Door Esp",
	Default = false,
	Callback = function(Value)
		Settings.EspSettings.DoorEsp.Enabled = Value
		if Value then
			DoorEsp()
		else
			StopDoorEsp()
		end
	end,
})

NameHiderTab = Tabs["Crosshair"]:AddRightTabbox("Name Hider")
MyNameTab = NameHiderTab:AddTab("My Settings")
MyNameTab:AddDivider()
OthersTab = NameHiderTab:AddTab("Other Players")

-- El motor del Name Hider corre si "My Settings" u "Other Players" estan activados.
-- Cada pestana tiene su propio boton de activar/desactivar.
local function RefreshNameHider()
	if NameHiderSettings.Enabled then
		StopNameHider()
	end
	if NameHiderSettings.MyEnabled or NameHiderSettings.OthersEnabled then
		StartNameHider()
	end
end

MyNameTab:AddToggle("EnableNameHider", {
	Text = "Enable Name Hider",
	Default = false,
	Callback = function(Value)
		NameHiderSettings.MyEnabled = Value
		RefreshNameHider()
	end,
})

MyNameTab:AddInput("MyCustomName", {
	Default = player.Name,
	Text = "Your Display Name",
	Callback = function(Value)
		NameHiderSettings.MyName = Value == "" and player.Name or Value
	end,
})
MyNameTab:AddInput("MyCustomLevel", {
	Default = "",
	Numeric = true,
	Text = "Your Display Level",
	Callback = function(Value)
		NameHiderSettings.MyLevel = tonumber(Value)
	end,
})

MyNameTab:AddDropdown("MyRankTag", {
	Values = MyRankList,
	Default = "None",
	Text = "Your Rank Tag",
	Callback = function(Value)
		if Value == "None" then
			NameHiderSettings.MyTag = nil
			NameHiderSettings.MyTagColor = nil
			NameHiderSettings.MyIcon = nil
		else
			NameHiderSettings.MyTag = Value
			NameHiderSettings.MyTagColor = RankData[Value].Color
			NameHiderSettings.MyIcon = RankData[Value].Icon
		end
	end,
})
MyNameTab:AddInput("MyCustomIcon", {
	Default = "",
	Text = "Custom Icon ID",
	Callback = function(Value)
		if Value ~= "" and string.find(Value, "rbxassetid://") then
			NameHiderSettings.MyIcon = Value
		end
	end,
})

MyNameTab:AddDivider()
MyNameTab:AddLabel("Avatar Changer")

MyNameTab:AddInput("MyAvatarTarget", {
	Default = "",
	Text = "Username or UserID",
})

MyNameTab:AddButton("Apply Avatar", function()
	local target = Options.MyAvatarTarget.Value
	if target and target ~= "" then
		applyavatar(player.Name, target)
	else
		Library:Notify("Please enter a username or UserID", 3)
	end
end)

MyNameTab:AddButton("Reset My Avatar", function()
	if player.Character then
		player.Character:BreakJoints()
	end
end)

selectedPlayer = nil

OthersTab:AddToggle("EnableOthersNameHider", {
	Text = "Enable Other Players",
	Default = false,
	Callback = function(Value)
		NameHiderSettings.OthersEnabled = Value
		RefreshNameHider()
	end,
})

OthersTab:AddDropdown("SelectPlayer", {
	Values = (function()
		local names = {}
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= player then
				table.insert(names, plr.Name)
			end
		end
		return names
	end)(),
	Default = "",
	Text = "Select Player",
	Callback = function(Value)
		selectedPlayer = Value
	end,
})

OthersTab:AddInput("OtherCustomName", {
	Default = "",
	Text = "Their Display Name",
	Callback = function(Value)
		if not selectedPlayer or selectedPlayer == "" then
			return
		end
		if not NameHiderSettings.CustomPlayers[selectedPlayer] then
			NameHiderSettings.CustomPlayers[selectedPlayer] = {}
		end
		NameHiderSettings.CustomPlayers[selectedPlayer].Name = Value == "" and selectedPlayer or Value
	end,
})
OthersTab:AddInput("OtherCustomLevel", {
	Default = "",
	Numeric = true,
	Text = "Their Display Level",
	Callback = function(Value)
		if not selectedPlayer or selectedPlayer == "" then
			return
		end
		if not NameHiderSettings.CustomPlayers[selectedPlayer] then
			NameHiderSettings.CustomPlayers[selectedPlayer] = {}
		end
		NameHiderSettings.CustomPlayers[selectedPlayer].Level = tonumber(Value)
	end,
})

OthersTab:AddDropdown("OtherRankTag", {
	Values = RankList,
	Default = "None",
	Text = "Their Rank Tag",
	Callback = function(Value)
		if not selectedPlayer or selectedPlayer == "" then
			return
		end

		if not NameHiderSettings.CustomPlayers[selectedPlayer] then
			NameHiderSettings.CustomPlayers[selectedPlayer] = {}
		end

		if Value == "None" then
			NameHiderSettings.CustomPlayers[selectedPlayer].Tag = nil
			NameHiderSettings.CustomPlayers[selectedPlayer].TagColor = nil
			NameHiderSettings.CustomPlayers[selectedPlayer].Icon = nil
		else
			NameHiderSettings.CustomPlayers[selectedPlayer].Tag = Value
			NameHiderSettings.CustomPlayers[selectedPlayer].TagColor = RankData[Value].Color
			NameHiderSettings.CustomPlayers[selectedPlayer].Icon = RankData[Value].Icon
		end
	end,
})

OthersTab:AddDivider()
OthersTab:AddLabel("Avatar Changer")

OthersTab:AddInput("OtherAvatarTarget", {
	Default = "",
	Text = "Avatar Username/UserID",
})

OthersTab:AddButton("Apply Avatar", function()
	if not selectedPlayer or selectedPlayer == "" then
		Library:Notify("Please select a player first", 3)
		return
	end

	local avatarTarget = Options.OtherAvatarTarget.Value
	if avatarTarget and avatarTarget ~= "" then
		applyavatar(selectedPlayer, avatarTarget)
	else
		Library:Notify("Please enter a username or UserID", 3)
	end
end)

OthersTab:AddButton("Reset Player Avatar", function()
	if not selectedPlayer or selectedPlayer == "" then
		Library:Notify("Please select a player first", 3)
		return
	end

	local targetPlayer = Players:FindFirstChild(selectedPlayer)
	if targetPlayer and targetPlayer.Character then
		targetPlayer.Character:BreakJoints()
	end
end)

OthersTab:AddButton("Clear Player Settings", function()
	if selectedPlayer and selectedPlayer ~= "" then
		NameHiderSettings.CustomPlayers[selectedPlayer] = nil
		Library:Notify("Cleared settings for " .. selectedPlayer, 3)
	end
end)

conn5 = Players.PlayerAdded:Connect(function(newPlayer)
	if Options.SelectPlayer then
		local values = Options.SelectPlayer.Values
		table.insert(values, newPlayer.Name)
		Options.SelectPlayer:SetValues(values)
	end
end)

conn6 = Players.PlayerRemoving:Connect(function(removingPlayer)
	if Options.SelectPlayer then
		local values = Options.SelectPlayer.Values
		local index = table.find(values, removingPlayer.Name)
		if index then
			table.remove(values, index)
			Options.SelectPlayer:SetValues(values)
		end
	end
	NameHiderSettings.CustomPlayers[removingPlayer.Name] = nil
end)

PlayerEspToggle = Groupboxes.Visual.RightGroupBox:AddToggle("PlayerEsp", {
	Text = "Player ESP",
	Default = false,
	Callback = function(Value)
		Settings.EspSettings.PlayerEsp.Enabled = Value
		if Settings.EspSettings.PlayerEsp.UseSkeletonEsp then
			for _, v in Players:GetPlayers() do
				if v.Character then
					RemovePlayerEsp(v.Character)
				end
			end
			return
		end
		if Value then
			for _, v in Players:GetPlayers() do
				if v ~= player and v.Character then
					AddPlayerEsp(v.Character)
				end
			end
		else
			for _, v in Players:GetPlayers() do
				if v.Character then
					RemovePlayerEsp(v.Character)
				end
			end
		end
	end,
})

UseCloneEspToggle = Groupboxes.Visual.RightGroupBox:AddToggle("UseCloneEsp", {
	Text = "Clone ESP Mode",
	Default = false,
	Callback = function(Value)
		Settings.EspSettings.PlayerEsp.UseCloneEsp = Value
		if Settings.EspSettings.PlayerEsp.UseSkeletonEsp then
			return
		end
		if Settings.EspSettings.PlayerEsp.Enabled then
			ReloadPlayerEsp()
		end
	end,
})

SkeletonEspToggle = Groupboxes.Visual.RightGroupBox:AddToggle("SkeletonEsp", {
	Text = "Skeleton ESP",
	Default = false,
	Callback = function(Value)
		Settings.EspSettings.PlayerEsp.UseSkeletonEsp = Value
		if Value then
			ReloadPlayerEsp()
			startSkeleton()
		else
			stopSkeletonEsp()
			ReloadPlayerEsp()
		end
	end,
})

TracersToggle = Groupboxes.Visual.RightGroupBox:AddToggle("Tracers", {
	Text = "Tracers",
	Default = false,
	Callback = function(Value)
		Settings.EspSettings.PlayerEsp.TracerSettings.Enabled = Value
		if Value then
			startTracers()
		else
			stopTracers()
		end
	end,
})

SurvivorFillPicker =
	Groupboxes.EspCustomization.PlayerEsp:AddLabel("Survivor Fil"):AddColorPicker("SurvivorFillPicker", {
		Default = Settings.EspSettings.PlayerEsp.SurvivorFillColor,
		Title = "Adjust Survivor Fill",
		Transparency = Settings.EspSettings.PlayerEsp.SurvivorFillTransparancy,
		Callback = function(value)
			Settings.EspSettings.PlayerEsp.SurvivorFillColor = value
			Settings.EspSettings.PlayerEsp.SurvivorFillTransparancy = Options.SurvivorFillPicker.Transparency
			UpdatePlayerEsp()
		end,
	})

SurvivorOutlinePicker =
	Groupboxes.EspCustomization.PlayerEsp:AddLabel("Survivor Outline"):AddColorPicker("SurvivorOutlinePicker", {
		Default = Settings.EspSettings.PlayerEsp.SurvivorOutlineColor,
		Title = "Adjust Survivor Outline",
		Transparency = Settings.EspSettings.PlayerEsp.SurvivorOutlineTransparancy,
		Callback = function(value)
			Settings.EspSettings.PlayerEsp.SurvivorOutlineColor = value
			Settings.EspSettings.PlayerEsp.SurvivorOutlineTransparancy = Options.SurvivorOutlinePicker.Transparency
			UpdatePlayerEsp()
		end,
	})

BeastFillPicker = Groupboxes.EspCustomization.PlayerEsp:AddLabel("Beast Fill"):AddColorPicker("BeastFillPicker", {
	Default = Settings.EspSettings.PlayerEsp.BeastFillColor,
	Title = "Adjust Beast Fill",
	Transparency = Settings.EspSettings.PlayerEsp.BeastFillTransparancy,
	Callback = function(value)
		Settings.EspSettings.PlayerEsp.BeastFillColor = value
		Settings.EspSettings.PlayerEsp.BeastFillTransparancy = Options.BeastFillPicker.Transparency
		UpdatePlayerEsp()
	end,
})

BeastOutlinePicker =
	Groupboxes.EspCustomization.PlayerEsp:AddLabel("Beast Outline"):AddColorPicker("BeastOutlinePicker", {
		Default = Settings.EspSettings.PlayerEsp.BeastOutlineColor,
		Title = "Adjust Beast Outline",
		Transparency = Settings.EspSettings.PlayerEsp.BeastOutlineTransparancy,
		Callback = function(value)
			Settings.EspSettings.PlayerEsp.BeastOutlineColor = value
			Settings.EspSettings.PlayerEsp.BeastOutlineTransparancy = Options.BeastOutlinePicker.Transparency
			UpdatePlayerEsp()
		end,
	})

PickTracerColor = Groupboxes.EspCustomization.Tracers:AddLabel("Color Picker"):AddColorPicker("PickTracer", {
	Default = Settings.EspSettings.PlayerEsp.TracerSettings.Color,
	Title = "Adjust tracer color",
	Transparency = Settings.EspSettings.PlayerEsp.TracerSettings.Transparancy,
	Callback = function(value)
		Settings.EspSettings.PlayerEsp.TracerSettings.Color = value
		Settings.EspSettings.PlayerEsp.TracerSettings.Transparancy = Options.PickTracer.Transparancy
		UpdateTracers()
	end,
})

TracerThicknessSlider = Groupboxes.EspCustomization.Tracers:AddSlider("Thickness Slider", {
	Default = Settings.EspSettings.PlayerEsp.TracerSettings.Thickness,
	Min = 0.5,
	Max = 15,
	Rounding = 1,
	Text = "Adjust the tracer thickness",
	Callback = function(value)
		Settings.EspSettings.PlayerEsp.TracerSettings.Thickness = value
		UpdateTracers()
	end,
})

TracerFromBottomToggle = Groupboxes.EspCustomization.Tracers:AddToggle("From Bottom", {
	Text = "Tracer start from bottom",
	Default = Settings.EspSettings.PlayerEsp.TracerSettings.FromBottom,
	Callback = function(value)
		Settings.EspSettings.PlayerEsp.TracerSettings.FromBottom = value
	end,
})

SkeletonColorPicker =
	Groupboxes.EspCustomization.Skeleton:AddLabel("SkeletonColor"):AddColorPicker("SkeletonColorPicker", {
		Default = Settings.EspSettings.PlayerEsp.SkeletonSettings.Color,
		Title = "Pick your skeleton esp color",
		Transparency = Settings.EspSettings.PlayerEsp.SkeletonSettings.Transparency,
		Callback = function(val)
			Settings.EspSettings.PlayerEsp.SkeletonSettings.Color = val
			Settings.EspSettings.PlayerEsp.SkeletonSettings.Transparency = Options.SkeletonColorPicker.Transparency
			UpdateSkeleton()
		end,
	})

SkeletonThicknessSlider = Groupboxes.EspCustomization.Skeleton:AddSlider("Skeleton Thickness", {
	Default = Settings.EspSettings.PlayerEsp.SkeletonSettings.Thickness,
	Min = 0.5,
	Max = 15,
	Rounding = 1,
	Text = "Adjust skeleton thickness",
	Callback = function(value)
		Settings.EspSettings.PlayerEsp.SkeletonSettings.Thickness = value
		UpdateSkeleton()
	end,
})

PcFillPicker = Groupboxes.EspCustomization.PcAndTube:AddLabel("Pc Fill"):AddColorPicker("PcFillPicker", {
	Default = Settings.EspSettings.PcEsp.FillColor,
	Title = "Adjust pc fill",
	Transparency = Settings.EspSettings.PcEsp.FillTransparency,
	Callback = function(value)
		Settings.EspSettings.PcEsp.FillColor = value
		Settings.EspSettings.PcEsp.FillTransparency = Options.PcFillPicker.Transparency
		UpdatePcEspColors()
	end,
})

PcDoneFillPicker = Groupboxes.EspCustomization.PcAndTube:AddLabel("Pc Done Fill"):AddColorPicker("PcDoneFillPicker", {
	Default = Settings.EspSettings.PcEsp.DoneFillColor,
	Title = "Adjust pc done fill",
	Callback = function(value)
		Settings.EspSettings.PcEsp.DoneFillColor = value
		UpdatePcEspColors()
	end,
})

TubeFillPicker = Groupboxes.EspCustomization.PcAndTube:AddLabel("Tube Fill"):AddColorPicker("TubeFillPicker", {
	Default = Settings.EspSettings.TubeEsp.FillColor,
	Title = "Adjust tube fill",
	Transparency = Settings.EspSettings.TubeEsp.FillTransparency,
	Callback = function(value)
		Settings.EspSettings.TubeEsp.FillColor = value
		Settings.EspSettings.TubeEsp.FillTransparency = Options.TubeFillPicker.Transparency
		UpdateTubeEspColors()
	end,
})

TubeOutlinePicker = Groupboxes.EspCustomization.PcAndTube:AddLabel("Tube Outline"):AddColorPicker("TubeOutlinePicker", {
	Default = Settings.EspSettings.TubeEsp.OutlineColor,
	Title = "Adjust tube outline",
	Transparency = Settings.EspSettings.TubeEsp.OutlineTransparency,
	Callback = function(value)
		Settings.EspSettings.TubeEsp.OutlineColor = value
		Settings.EspSettings.TubeEsp.OutlineTransparency = Options.TubeOutlinePicker.Transparency
		UpdateTubeEspColors()
	end,
})

OpenDoorFillPicker =
	Groupboxes.EspCustomization.DoorEsp:AddLabel("Open Door Fill"):AddColorPicker("OpenDoorFillPicker", {
		Default = Settings.EspSettings.DoorEsp.OpenColor,
		Title = "Adjust open door fill",
		Transparency = Settings.EspSettings.DoorEsp.OpenFillTransparency,
		Callback = function(value)
			Settings.EspSettings.DoorEsp.OpenColor = value
			Settings.EspSettings.DoorEsp.OpenFillTransparency = Options.OpenDoorFillPicker.Transparency
			UpdateDoorEspColors()
		end,
	})

OpenDoorOutlinePicker =
	Groupboxes.EspCustomization.DoorEsp:AddLabel("Open Door Outline"):AddColorPicker("OpenDoorOutlinePicker", {
		Default = Settings.EspSettings.DoorEsp.OpenOutlineColor,
		Title = "Adjust open door outline",
		Transparency = Settings.EspSettings.DoorEsp.OutlineTransparency,
		Callback = function(value)
			Settings.EspSettings.DoorEsp.OpenOutlineColor = value
			Settings.EspSettings.DoorEsp.OutlineTransparency = Options.OpenDoorOutlinePicker.Transparency
			UpdateDoorEspColors()
		end,
	})

ClosedDoorFillPicker =
	Groupboxes.EspCustomization.DoorEsp:AddLabel("Closed Door Fill"):AddColorPicker("ClosedDoorFillPicker", {
		Default = Settings.EspSettings.DoorEsp.ClosedColor,
		Title = "Adjust closed door fill",
		Transparency = Settings.EspSettings.DoorEsp.ClosedFillTransparency,
		Callback = function(value)
			Settings.EspSettings.DoorEsp.ClosedColor = value
			Settings.EspSettings.DoorEsp.ClosedFillTransparency = Options.ClosedDoorFillPicker.Transparency
			UpdateDoorEspColors()
		end,
	})

ClosedDoorOutlinePicker =
	Groupboxes.EspCustomization.DoorEsp:AddLabel("Closed Door Outline"):AddColorPicker("ClosedDoorOutlinePicker", {
		Default = Settings.EspSettings.DoorEsp.ClosedOutlineColor,
		Title = "Adjust closed door outline",
		Transparency = Settings.EspSettings.DoorEsp.OutlineTransparency,
		Callback = function(value)
			Settings.EspSettings.DoorEsp.ClosedOutlineColor = value
			Settings.EspSettings.DoorEsp.OutlineTransparency = Options.ClosedDoorOutlinePicker.Transparency
			UpdateDoorEspColors()
		end,
	})

PcProgressToggle = Groupboxes.Gadgets.Left:AddToggle("PcProgress", {
	Text = "PC Progress",
	Default = false,
	Callback = function(Value)
		Settings.GadgetSettings.ProgressSettings.PcProgress.Enabled = Value
		maintainObjectUIs()
	end,
})

ExitProgressToggle = Groupboxes.Gadgets.Left:AddToggle("ExitProgress", {
	Text = "Exit Progress",
	Default = false,
	Callback = function(Value)
		Settings.GadgetSettings.ProgressSettings.ExitProgress.Enabled = Value
		maintainObjectUIs()
	end,
})

DoorProgressToggle = Groupboxes.Gadgets.Left:AddToggle("DoorProgress", {
	Text = "Door Progress",
	Default = false,
	Callback = function(Value)
		Settings.GadgetSettings.ProgressSettings.DoorProgress.Enabled = Value
		maintainObjectUIs()
	end,
})

GetupTimerToggle = Groupboxes.Gadgets.Right:AddToggle("GetupTimer", {
	Text = "Getup Timer",
	Default = false,
	Callback = function(Value)
		Settings.GadgetSettings.ProgressSettings.GetupTimer.Enabled = Value
	end,
})

RunnerTimerToggle = Groupboxes.Gadgets.Right:AddToggle("RunnerTimer", {
	Text = "Runner Timer",
	Default = false,
	Callback = function(Value)
		Settings.GadgetSettings.ProgressSettings.RunnerTimer.Enabled = Value
		if Value then
			StartRunnerTimer()
		else
			StopRunnerTimer()
		end
	end,
})

BlackRemoverToggle = Groupboxes.Gadgets.OtherGadgets:AddToggle("Black Remover", {
	Text = "Black screen remover",
	Default = Settings.GadgetSettings.OtherGadgets.HideBlack,
	Callback = function(Value)
		Settings.GadgetSettings.OtherGadgets.HideBlack = not Value
		local ui = playergui:FindFirstChild("BlackOutScreenGui")
		ui.Enabled = not Value
	end,
})

WalkspeedDetectorToggle = Groupboxes.Gadgets.OtherGadgets:AddToggle("Walkspeed Detector", {
	Text = "Walkspeed Detector",
	Default = false,
	Callback = function(Value)
		Settings.GadgetSettings.OtherGadgets.WalkspeedDetector.Enabled = Value
		if Value then
			StartWalkspeedLoop()
			for _, plr in pairs(Players:GetPlayers()) do
				if plr ~= player and plr.Character then
					CreateWalkspeedUI(plr.Character)
				end
			end
		else
			StopWalkspeedLoop()
			for character, ui in pairs(WalkspeedUIs) do
				RemoveWalkspeedUI(character)
			end
		end
	end,
})

HeadstartTracker = Groupboxes.Gadgets.OtherGadgets:AddToggle("Headstart Tracker", {
	Default = Settings.GadgetSettings.OtherGadgets.HeadstartTracker.Enabled,
	Text = "Headstart tracker",
	Callback = function(val)
		Settings.GadgetSettings.OtherGadgets.HeadstartTracker.Enabled = val
	end,
})

NeverFailToggle = Groupboxes.Gadgets.OtherGadgets:AddToggle("Never Fail Hacking", {
	Default = Settings.GadgetSettings.OtherGadgets.NeverFail,
	Text = "Never Fail",
	Callback = function(val)
		Settings.GadgetSettings.OtherGadgets.NeverFail = val
		SetNeverFail(val)
	end,
})

WalkspeedTextPicker = WalkspeedCustomization:AddLabel("Text Color"):AddColorPicker("WalkspeedTextPicker", {
	Default = Settings.GadgetSettings.OtherGadgets.WalkspeedDetector.TextColor,
	Title = "Walkspeed Text Color",
	Transparency = Settings.GadgetSettings.OtherGadgets.WalkspeedDetector.TextTransparency,
	Callback = function(value)
		Settings.GadgetSettings.OtherGadgets.WalkspeedDetector.TextColor = value
		Settings.GadgetSettings.OtherGadgets.WalkspeedDetector.TextTransparency =
			Options.WalkspeedTextPicker.Transparency
		UpdateWalkspeedColors()
	end,
})

WalkspeedStrokePicker = WalkspeedCustomization:AddLabel("Stroke Color"):AddColorPicker("WalkspeedStrokePicker", {
	Default = Settings.GadgetSettings.OtherGadgets.WalkspeedDetector.StrokeColor,
	Title = "Walkspeed Stroke Color",
	Transparency = Settings.GadgetSettings.OtherGadgets.WalkspeedDetector.StrokeTransparency,
	Callback = function(value)
		Settings.GadgetSettings.OtherGadgets.WalkspeedDetector.StrokeColor = value
		Settings.GadgetSettings.OtherGadgets.WalkspeedDetector.StrokeTransparency =
			Options.WalkspeedStrokePicker.Transparency
		UpdateWalkspeedColors()
	end,
})

PcTextColorPicker =
	Groupboxes.GadgetCustomization.PcProgress:AddLabel("Text Color"):AddColorPicker("PcTextColorPicker", {
		Default = Settings.GadgetSettings.ProgressSettings.PcProgress.TextColor,
		Title = "PC Progress Text Color",
		Transparency = 0,
		Callback = function(value)
			Settings.GadgetSettings.ProgressSettings.PcProgress.TextColor = value
			maintainObjectUIs()
		end,
	})

PcProgressFillPicker =
	Groupboxes.GadgetCustomization.PcProgress:AddLabel("Progress Fill"):AddColorPicker("PcProgressFillPicker", {
		Default = Settings.GadgetSettings.ProgressSettings.PcProgress.ProgressFill,
		Title = "PC Progress Fill Color",
		Transparency = Settings.GadgetSettings.ProgressSettings.PcProgress.ProgressTransparancy,
		Callback = function(value)
			Settings.GadgetSettings.ProgressSettings.PcProgress.ProgressFill = value
			Settings.GadgetSettings.ProgressSettings.PcProgress.ProgressTransparancy =
				Options.PcProgressFillPicker.Transparency
			maintainObjectUIs()
		end,
	})

local PcBackgroundPicker =
	Groupboxes.GadgetCustomization.PcProgress:AddLabel("Background"):AddColorPicker("PcBackgroundPicker", {
		Default = Settings.GadgetSettings.ProgressSettings.PcProgress.BackgroundColor,
		Title = "PC Progress Background",
		Transparency = Settings.GadgetSettings.ProgressSettings.PcProgress.BackgroundTransparancy,
		Callback = function(value)
			Settings.GadgetSettings.ProgressSettings.PcProgress.BackgroundColor = value
			Settings.GadgetSettings.ProgressSettings.PcProgress.BackgroundTransparancy =
				Options.PcBackgroundPicker.Transparency
			maintainObjectUIs()
		end,
	})

local PcDisplaySecondsToggle = Groupboxes.GadgetCustomization.PcProgress:AddToggle("PcDisplaySeconds", {
	Text = "Display Seconds",
	Default = Settings.GadgetSettings.ProgressSettings.PcProgress.DisplaySeconds,
	Callback = function(Value)
		Settings.GadgetSettings.ProgressSettings.PcProgress.DisplaySeconds = Value
		maintainObjectUIs()
	end,
})

local ExitTextColorPicker =
	Groupboxes.GadgetCustomization.ExitProgress:AddLabel("Text Color"):AddColorPicker("ExitTextColorPicker", {
		Default = Settings.GadgetSettings.ProgressSettings.ExitProgress.TextColor,
		Title = "Exit Progress Text Color",
		Transparency = 0,
		Callback = function(value)
			Settings.GadgetSettings.ProgressSettings.ExitProgress.TextColor = value
			maintainObjectUIs()
		end,
	})

local ExitProgressFillPicker =
	Groupboxes.GadgetCustomization.ExitProgress:AddLabel("Progress Fill"):AddColorPicker("ExitProgressFillPicker", {
		Default = Settings.GadgetSettings.ProgressSettings.ExitProgress.ProgressFill,
		Title = "Exit Progress Fill Color",
		Transparency = Settings.GadgetSettings.ProgressSettings.ExitProgress.ProgressTransparancy,
		Callback = function(value)
			Settings.GadgetSettings.ProgressSettings.ExitProgress.ProgressFill = value
			Settings.GadgetSettings.ProgressSettings.ExitProgress.ProgressTransparancy =
				Options.ExitProgressFillPicker.Transparency
			maintainObjectUIs()
		end,
	})

ExitBackgroundPicker =
	Groupboxes.GadgetCustomization.ExitProgress:AddLabel("Background"):AddColorPicker("ExitBackgroundPicker", {
		Default = Settings.GadgetSettings.ProgressSettings.ExitProgress.BackgroundColor,
		Title = "Exit Progress Background",
		Transparency = Settings.GadgetSettings.ProgressSettings.ExitProgress.BackgroundTransparancy,
		Callback = function(value)
			Settings.GadgetSettings.ProgressSettings.ExitProgress.BackgroundColor = value
			Settings.GadgetSettings.ProgressSettings.ExitProgress.BackgroundTransparancy =
				Options.ExitBackgroundPicker.Transparency
			maintainObjectUIs()
		end,
	})

ExitDisplaySecondsToggle = Groupboxes.GadgetCustomization.ExitProgress:AddToggle("ExitDisplaySeconds", {
	Text = "Display Seconds",
	Default = Settings.GadgetSettings.ProgressSettings.ExitProgress.DisplaySeconds,
	Callback = function(Value)
		Settings.GadgetSettings.ProgressSettings.ExitProgress.DisplaySeconds = Value
		maintainObjectUIs()
	end,
})

DoorTextColorPicker =
	Groupboxes.GadgetCustomization.DoorProgress:AddLabel("Text Color"):AddColorPicker("DoorTextColorPicker", {
		Default = Settings.GadgetSettings.ProgressSettings.DoorProgress.TextColor,
		Title = "Door Progress Text Color",
		Transparency = 0,
		Callback = function(value)
			Settings.GadgetSettings.ProgressSettings.DoorProgress.TextColor = value
			maintainObjectUIs()
		end,
	})

DoorProgressFillPicker =
	Groupboxes.GadgetCustomization.DoorProgress:AddLabel("Progress Fill"):AddColorPicker("DoorProgressFillPicker", {
		Default = Settings.GadgetSettings.ProgressSettings.DoorProgress.ProgressFill,
		Title = "Door Progress Fill Color",
		Transparency = Settings.GadgetSettings.ProgressSettings.DoorProgress.ProgressTransparancy,
		Callback = function(value)
			Settings.GadgetSettings.ProgressSettings.DoorProgress.ProgressFill = value
			Settings.GadgetSettings.ProgressSettings.DoorProgress.ProgressTransparancy =
				Options.DoorProgressFillPicker.Transparency
			maintainObjectUIs()
		end,
	})

DoorBackgroundPicker =
	Groupboxes.GadgetCustomization.DoorProgress:AddLabel("Background"):AddColorPicker("DoorBackgroundPicker", {
		Default = Settings.GadgetSettings.ProgressSettings.DoorProgress.BackgroundColor,
		Title = "Door Progress Background",
		Transparency = Settings.GadgetSettings.ProgressSettings.DoorProgress.BackgroundTransparancy,
		Callback = function(value)
			Settings.GadgetSettings.ProgressSettings.DoorProgress.BackgroundColor = value
			Settings.GadgetSettings.ProgressSettings.DoorProgress.BackgroundTransparancy =
				Options.DoorBackgroundPicker.Transparency
			maintainObjectUIs()
		end,
	})

DoorDisplaySecondsToggle = Groupboxes.GadgetCustomization.DoorProgress:AddToggle("DoorDisplaySeconds", {
	Text = "Display Seconds",
	Default = Settings.GadgetSettings.ProgressSettings.DoorProgress.DisplaySeconds,
	Callback = function(Value)
		Settings.GadgetSettings.ProgressSettings.DoorProgress.DisplaySeconds = Value
		maintainObjectUIs()
	end,
})

GetupNotHitColorPicker =
	Groupboxes.GadgetCustomization.GetupTimer:AddLabel("Not Hit Color"):AddColorPicker("GetupNotHitColorPicker", {
		Default = Settings.GadgetSettings.ProgressSettings.GetupTimer.NotHitColor,
		Title = "Color When Not Time to Hit",
		Transparency = 0,
		Callback = function(value)
			Settings.GadgetSettings.ProgressSettings.GetupTimer.NotHitColor = value
			UpdateGetupTimerColors()
		end,
	})

GetupHitColorPicker =
	Groupboxes.GadgetCustomization.GetupTimer:AddLabel("Hit Color"):AddColorPicker("GetupHitColorPicker", {
		Default = Settings.GadgetSettings.ProgressSettings.GetupTimer.HitColor,
		Title = "Color When Time to Hit",
		Transparency = 0,
		Callback = function(value)
			Settings.GadgetSettings.ProgressSettings.GetupTimer.HitColor = value
			UpdateGetupTimerColors()
		end,
	})

GetupWhenToHitSlider = Groupboxes.GadgetCustomization.GetupTimer:AddSlider("GetupWhenToHit", {
	Default = Settings.GadgetSettings.ProgressSettings.GetupTimer.WhenToHit,
	Min = 0,
	Max = 5,
	Rounding = 2,
	Text = "When to Hit (seconds)",
	Callback = function(value)
		Settings.GadgetSettings.ProgressSettings.GetupTimer.WhenToHit = value
		UpdateGetupTimerColors()
	end,
})

Groupboxes.GadgetCustomization.GetupTimer:AddToggle("SmoothGetupTimer", {
	Text = "Smooth getup",
	Default = true,
	Callback = function(Value)
		Settings.GadgetSettings.ProgressSettings.GetupTimer.SmoothMode = Value
	end,
})

Groupboxes.GadgetCustomization.GetupTimer:AddSlider("GetupUpdateRate", {
	Default = 20,
	Min = 1,
	Max = 100,
	Rounding = 0,
	Text = "Update Rate (ms)",
	Callback = function(Value)
		Settings.GadgetSettings.ProgressSettings.GetupTimer.UpdateRate = Value / 1000
	end,
})

-- SONIDO GET UP
Groupboxes.GadgetCustomization.GetupTimer:AddToggle("GetupSoundToggle", {
	Text = "Sonido al Get Up",
	Default = false,
	Callback = function(Value)
		Settings.GadgetSettings.ProgressSettings.GetupTimer.SoundEnabled = Value
	end,
})

Groupboxes.GadgetCustomization.GetupTimer:AddSlider("GetupSoundSeconds", {
	Default = 6,
	Min = 2,
	Max = 6,
	Rounding = 0,
	Text = "Segundos antes del sonido",
	Callback = function(Value)
		Settings.GadgetSettings.ProgressSettings.GetupTimer.SoundSecondsLeft = Value
	end,
})

RunnerTextColorPicker =
	Groupboxes.GadgetCustomization.RunnerTimer:AddLabel("Text Color"):AddColorPicker("RunnerTextColorPicker", {
		Default = Settings.GadgetSettings.ProgressSettings.RunnerTimer.TextColor,
		Title = "Runner Timer Text Color",
		Transparency = 0,
		Callback = function(value)
			Settings.GadgetSettings.ProgressSettings.RunnerTimer.TextColor = value
			UpdateRunnerTimerColor()
		end,
	})

-- ════════════════════════════════════════════════════
-- RUNNER NOTICE (cartel en pantalla)
-- ════════════════════════════════════════════════════
RunnerNotice = { Gui = nil, Conn = nil }

do
	local TweenService = game:GetService("TweenService")
	local USED_COLOR = Color3.fromRGB(255, 55, 55)
	local NOTICE_Y = 0.85

	local Notice, Percent
	local state = "hidden"

	local function GetPercent(value)
		if value <= 1 then
			return math.clamp(math.round(value * 100), 0, 100)
		end
		return math.clamp(math.round(value), 0, 100)
	end

	local function Build()
		local gui = Instance.new("ScreenGui")
		gui.Name = "RunnerNotificationGUI"
		gui.ResetOnSpawn = false
		gui.IgnoreGuiInset = true
		if syn and syn.protect_gui then
			pcall(syn.protect_gui, gui)
		end
		gui.Parent = CoreGui

		Notice = Instance.new("Frame")
		Notice.Name = "RunnerNotice"
		Notice.AnchorPoint = Vector2.new(0.5, 0)
		Notice.Size = UDim2.new(0, 178, 0, 62)
		Notice.Position = UDim2.new(0.5, 0, NOTICE_Y, 0)
		Notice.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
		Notice.BackgroundTransparency = 0.08
		Notice.BorderSizePixel = 0
		Notice.Visible = false
		Notice.ZIndex = 2
		Notice.ClipsDescendants = true
		Notice.Parent = gui

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 7)
		corner.Parent = Notice

		local bar = Instance.new("Frame")
		bar.Name = "ColorBar"
		bar.Size = UDim2.new(0, 4, 1, 0)
		bar.BackgroundColor3 = USED_COLOR
		bar.BorderSizePixel = 0
		bar.ZIndex = 3
		bar.Parent = Notice

		local icon = Instance.new("TextLabel")
		icon.Name = "Icon"
		icon.Size = UDim2.new(0, 45, 0, 45)
		icon.Position = UDim2.new(0, 8, 0.5, -22)
		icon.BackgroundTransparency = 1
		icon.Text = "⚙"
		icon.TextColor3 = Color3.fromRGB(255, 255, 255)
		icon.TextSize = 31
		icon.Font = Enum.Font.SourceSansBold
		icon.ZIndex = 3
		icon.Parent = Notice

		local title = Instance.new("TextLabel")
		title.Name = "Title"
		title.Size = UDim2.new(1, -56, 0, 18)
		title.Position = UDim2.new(0, 52, 0, 5)
		title.BackgroundTransparency = 1
		title.Text = "THE BEAST"
		title.TextColor3 = Color3.fromRGB(255, 255, 255)
		title.TextSize = 15
		title.Font = Enum.Font.GothamBlack
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.ZIndex = 3
		title.Parent = Notice

		-- Porcentaje grande, centrado donde antes iba el mensaje "used their Runner"
		Percent = Instance.new("TextLabel")
		Percent.Name = "Percent"
		Percent.Size = UDim2.new(1, -56, 0, 34)
		Percent.Position = UDim2.new(0, 52, 0, 23)
		Percent.BackgroundTransparency = 1
		Percent.Text = ""
		Percent.TextColor3 = USED_COLOR
		Percent.TextSize = 30
		Percent.Font = Enum.Font.GothamBlack
		Percent.TextXAlignment = Enum.TextXAlignment.Left
		Percent.ZIndex = 3
		Percent.Parent = Notice

		return gui
	end

	local function ShowNotice(percent)
		local percentText = percent .. "%"
		if Percent.Text ~= percentText then
			Percent.Text = percentText
		end
		if state == "shown" then
			return
		end
		state = "shown"

		Notice.Visible = true
		Notice.Position = UDim2.new(0.5, 0, NOTICE_Y, 12)
		Notice.BackgroundTransparency = 1

		TweenService:Create(Notice, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, 0, NOTICE_Y, 0),
			BackgroundTransparency = 0.08,
		}):Play()
	end

	local function HideNotice()
		if state ~= "shown" then
			return
		end
		state = "hiding"

		local tween = TweenService:Create(Notice, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(0.5, 0, NOTICE_Y, 12),
			BackgroundTransparency = 1,
		})
		tween:Play()
		tween.Completed:Once(function()
			if state == "hiding" and Notice then
				state = "hidden"
				Notice.Visible = false
				Notice.Position = UDim2.new(0.5, 0, NOTICE_Y, 0)
			end
		end)
	end

	local function UpdateNotice()
		if not Settings.GadgetSettings.ProgressSettings.RunnerTimer.Enabled then
			HideNotice()
			return
		end

		local percentToShow = nil

		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= player and plr.Character then
				local beastFolder = plr.Character:FindFirstChild("BeastPowers")
				local numberValue = beastFolder and beastFolder:FindFirstChildOfClass("NumberValue")
				if numberValue then
					local pct = GetPercent(numberValue.Value)
					if pct < 100 then
						percentToShow = pct
						break
					end
				end
			end
		end

		if percentToShow ~= nil then
			ShowNotice(percentToShow)
		else
			HideNotice()
		end
	end

	function RunnerNotice.Start()
		RunnerNotice.Stop()
		RunnerNotice.Gui = Build()
		state = "hidden"
		local last = 0
		RunnerNotice.Conn = RunService.Heartbeat:Connect(function()
			local now = os.clock()
			if now - last >= 0.1 then
				last = now
				UpdateNotice()
			end
		end)
	end

	function RunnerNotice.Stop()
		if RunnerNotice.Conn then
			RunnerNotice.Conn:Disconnect()
			RunnerNotice.Conn = nil
		end
		if RunnerNotice.Gui then
			RunnerNotice.Gui:Destroy()
			RunnerNotice.Gui = nil
		end
		Notice, Percent = nil, nil
		state = "hidden"
	end
end

RunnerDisplaySecondsToggle = Groupboxes.GadgetCustomization.RunnerTimer:AddToggle("RunnerDisplaySeconds", {
	Text = "Display Seconds",
	Default = Settings.GadgetSettings.ProgressSettings.RunnerTimer.DisplaySeconds,
	Callback = function(Value)
		Settings.GadgetSettings.ProgressSettings.RunnerTimer.DisplaySeconds = Value
	end,
})

RunnerShowOnScreenToggle = Groupboxes.GadgetCustomization.RunnerTimer:AddToggle("RunnerShowOnScreen", {
	Text = "Show on Screen",
	Default = false,
	Callback = function(Value)
		if Value then
			RunnerNotice.Start()
		else
			RunnerNotice.Stop()
		end
	end,
})

HeadstartColorChanged =
	Groupboxes.GadgetCustomization.HeadstartTracker:AddLabel("Text color changer"):AddColorPicker("TextColorChanged", {
		Default = Settings.GadgetSettings.OtherGadgets.HeadstartTracker.TextColor,
		Title = "Text color changer",
		Transparency = Settings.GadgetSettings.OtherGadgets.HeadstartTracker.TextTransparancy,
		Callback = function(val)
			Settings.GadgetSettings.OtherGadgets.HeadstartTracker.TextColor = val
			Settings.GadgetSettings.OtherGadgets.HeadstartTracker.TextTransparancy =
				Options.TextColorChanged.Transparency
			UpdateHeadstartTimer()
		end,
	})

ExitEspToggle = Groupboxes.Visual.LeftGroupBox:AddToggle("ExitEsp", {
	Text = "Exit ESP",
	Default = false,
	Callback = function(Value)
		Settings.EspSettings.ExitEsp.Enabled = Value
		if Value then
			StartExitEsp()
		else
			StopExitEsp()
		end
	end,
})

Groupboxes.Visual.LeftGroupBox:AddDivider()
Groupboxes.Visual.LeftGroupBox:AddLabel("Random")

NoFogToggle = Groupboxes.Visual.LeftGroupBox:AddToggle("NoFog", {
	Text = "No Fog",
	Default = false,
	Callback = function(Value)
		FogSettings.Enabled = Value
		if Value then
			local bf = Library.Toggles.BlackFog
			if bf and bf.Value then
				bf:SetValue(false)
			end
			EnableNoFog()
		else
			DisableNoFog()
		end
	end,
})

function setupblackfog()
	if Lighting:FindFirstChild("BlackFogConfig") then
		return
	end
	local config = Instance.new("Folder")
	config.Name = "BlackFogConfig"
	config.Parent = Lighting
	local atm = Lighting:FindFirstChildOfClass("Atmosphere")
	if atm then
		local origColor = Instance.new("Color3Value", config)
		origColor.Name = "Color"
		origColor.Value = atm.Color
		local origGlare = Instance.new("NumberValue", config)
		origGlare.Name = "Glare"
		origGlare.Value = atm.Glare
		local origHaze = Instance.new("NumberValue", config)
		origHaze.Name = "Haze"
		origHaze.Value = atm.Haze
		local origDecay = Instance.new("Color3Value", config)
		origDecay.Name = "Decay"
		origDecay.Value = atm.Decay
		local origDensity = Instance.new("NumberValue", config)
		origDensity.Name = "Density"
		origDensity.Value = RealAtmDensity(atm)
		local origOffset = Instance.new("NumberValue", config)
		origOffset.Name = "Offset"
		origOffset.Value = atm.Offset
	end
	task.spawn(function()
		while Lighting:FindFirstChild("BlackFogConfig") do
			local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
			if not atmosphere then
				atmosphere = Instance.new("Atmosphere")
				atmosphere.Parent = Lighting
			end
			if atmosphere.Density ~= (IsBoosting() and 0 or 0.75) or atmosphere.Haze ~= 2.46 then
				atmosphere.Color = Color3.fromRGB(0, 0, 0)
				atmosphere.Glare = 0
				atmosphere.Haze = 2.46
				atmosphere.Decay = Color3.fromRGB(0, 0, 0)
				atmosphere.Density = IsBoosting() and 0 or 0.75
				atmosphere.Offset = 0
			end
			task.wait(1)
		end
	end)
end

function cleanupblackfog()
	local config = Lighting:FindFirstChild("BlackFogConfig")
	if not config then
		return
	end
	local atm = Lighting:FindFirstChildOfClass("Atmosphere")
	if atm then
		local colorVal = config:FindFirstChild("Color")
		if colorVal then
			atm.Color = colorVal.Value
			atm.Glare = config.Glare.Value
			atm.Haze = config.Haze.Value
			atm.Decay = config.Decay.Value
			atm.Density = config.Density.Value
			atm.Offset = config.Offset.Value
		else
			atm:Destroy()
		end
	end
	config:Destroy()
	BoostKeepAtmosphere()
end

Groupboxes.Visual.LeftGroupBox:AddToggle("BlackFog", {
	Text = "Black fog",
	Default = false,
	Callback = function(Value)
		if Value then
			local nf = Library.Toggles.NoFog
			if nf and nf.Value then
				nf:SetValue(false)
			end
			setupblackfog()
			BlackFogGamma_Auto(true)
		else
			cleanupblackfog()
			BlackFogGamma_Auto(false)
		end
	end,
})

WallhopsToggle = Groupboxes.Visual.LeftGroupBox
	:AddToggle("Wallhops", {
		Text = "Show Wallhops",
		Default = false,
		Callback = function(Value)
			WallhopSettings.Enabled = Value
			if Value then
				EnableWallhops()
			else
				DisableWallhops()
			end
		end,
	})
	:AddKeyPicker(
		"WallhopsKey",
		{ Default = "None", SyncToggleState = true, Mode = "Toggle", Text = "Toggle Wallhops", NoUI = false }
	)

BarrierToggle = Groupboxes.Visual.LeftGroupBox:AddToggle("BarrierVisibility", {
	Text = "Barrier Visibility",
	Default = false,
	Callback = function(Value)
		BarrierSettings.Enabled = Value
		if Value then
			EnableBarrierVisibility()
		else
			DisableBarrierVisibility()
		end
	end,
})

HeadstartStrokeColorChanged = Groupboxes.GadgetCustomization.HeadstartTracker
	:AddLabel("Stroke color changer")
	:AddColorPicker("HeadstartStrokeColorChanged", {
		Default = Settings.GadgetSettings.OtherGadgets.HeadstartTracker.StrokeColor,
		Title = "Stroke color changer",
		Transparency = Settings.GadgetSettings.OtherGadgets.HeadstartTracker.StrokeTransparancy,
		Callback = function(val)
			Settings.GadgetSettings.OtherGadgets.HeadstartTracker.StrokeColor = val
			Settings.GadgetSettings.OtherGadgets.HeadstartTracker.StrokeTransparancy =
				Options.HeadstartStrokeColorChanged.Transparency
			UpdateHeadstartTimer()
		end,
	})
for _, plr in pairs(Players:GetPlayers()) do
	if plr ~= player then
		trackPlayer(plr)
	end

	onRagdollChanged(plr)
end

for _, plr in pairs(Players:GetPlayers()) do
	if plr ~= player then
		trackPlayer(plr)

		if plr.Character then
			CreateRunnerTimerLabel(plr)
		end

		plr.CharacterAdded:Connect(function(character)
			CreateRunnerTimerLabel(plr)
		end)

		setupRagdollMonitoring(plr)
	end

	onRagdollChanged(plr)
end

conn7 = Players.PlayerAdded:Connect(function(newPlayer)
	if newPlayer ~= player then
		trackPlayer(newPlayer)

		newPlayer.CharacterAdded:Connect(function(character)
			character:WaitForChild("HumanoidRootPart")
			task.wait(0.5)
			CreateRunnerTimerLabel(newPlayer)
			setupRagdollMonitoring(newPlayer)
		end)

		onRagdollChanged(newPlayer)
		setupRagdollMonitoring(newPlayer)
	end
	if Settings.EspSettings.PcEsp.Enabled then
		StopPcEsp()
		StartPcEsp()
	end
	if Settings.EspSettings.TubeEsp.Enabled then
		StopTubeEsp()
		StartTubeEsp()
	end
end)

conn8 = Players.PlayerRemoving:Connect(function(removingPlayer)
	if removingPlayer ~= player then
		untrackPlayer(removingPlayer)

		if previousValues[removingPlayer.UserId] then
			previousValues[removingPlayer.UserId] = nil
		end

		removeBottomRightUI(removingPlayer)

		local index = table.find(HitPlayers, removingPlayer)
		if index then
			table.remove(HitPlayers, index)
		end

		updateUIPositions()

		if GetupConnections[removingPlayer] then
			GetupConnections[removingPlayer]:Disconnect()
			GetupConnections[removingPlayer] = nil
		end

	end
end)

do
	local LeftSpeedTab = DangerSettingsTabBox:AddTab("Speed Settings")

	local SpeedToggle = LeftSpeedTab:AddToggle("SpeedEnabled", {
		Text = "Enable Speed",
		Default = false,
		Callback = function(Value)
			SpeedSettings.Enabled = Value
			if Value then
				ApplySpeed()
			else
				ResetSpeed()
			end
		end,
	}):AddKeyPicker(
		"SpeedKey",
		{ Default = "None", SyncToggleState = true, Mode = "Toggle", Text = "Speed Booster", NoUI = false }
	)

	-- Boton en pantalla (movil) para activar/desactivar Speed, igual que la keybind de PC
	do
		if CoreGui:FindFirstChild("SpeedScreenButtonGui") then
			CoreGui.SpeedScreenButtonGui:Destroy()
		end

		local SpeedScreenGui = Instance.new("ScreenGui")
		SpeedScreenGui.Name = "SpeedScreenButtonGui"
		SpeedScreenGui.ResetOnSpawn = false
		SpeedScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		if syn and syn.protect_gui then
			pcall(syn.protect_gui, SpeedScreenGui)
		end
		SpeedScreenGui.Parent = CoreGui

		local SpeedScreenButton = Instance.new("TextButton")
		SpeedScreenButton.Name = "SpeedButton"
		SpeedScreenButton.Parent = SpeedScreenGui
		SpeedScreenButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
		SpeedScreenButton.BackgroundTransparency = 0.2
		SpeedScreenButton.Position = UDim2.new(0, 20, 1, -140)
		SpeedScreenButton.Size = UDim2.new(0, 120, 0, 45)
		SpeedScreenButton.Font = Enum.Font.GothamBold
		SpeedScreenButton.Text = "SPEED: OFF"
		SpeedScreenButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		SpeedScreenButton.TextSize = 16
		SpeedScreenButton.AutoButtonColor = true
		SpeedScreenButton.Visible = false

		local SpeedBtnCorner = Instance.new("UICorner")
		SpeedBtnCorner.CornerRadius = UDim.new(0, 8)
		SpeedBtnCorner.Parent = SpeedScreenButton

		local SpeedBtnStroke = Instance.new("UIStroke")
		SpeedBtnStroke.Color = Color3.fromRGB(200, 60, 60)
		SpeedBtnStroke.Thickness = 2
		SpeedBtnStroke.Parent = SpeedScreenButton

		local SpeedDrag = DragGui(SpeedScreenButton)

		local function RefreshSpeedButton()
			local on = Library.Toggles.SpeedEnabled and Library.Toggles.SpeedEnabled.Value
			SpeedScreenButton.Text = on and "SPEED: ON" or "SPEED: OFF"
			SpeedBtnStroke.Color = on and Color3.fromRGB(60, 200, 60) or Color3.fromRGB(200, 60, 60)
		end

		SpeedScreenButton.MouseButton1Click:Connect(function()
			if SpeedDrag.Moved then
				return
			end
			local t = Library.Toggles.SpeedEnabled
			if t then
				t:SetValue(not t.Value)
			end
		end)

		Library.Toggles.SpeedEnabled:OnChanged(RefreshSpeedButton)

		LeftSpeedTab:AddToggle("SpeedShowOnScreen", {
			Text = "Show on Screen",
			Default = false,
			Callback = function(Value)
				SpeedScreenButton.Visible = Value
				RefreshSpeedButton()
			end,
		})
	end

	LeftSpeedTab:AddInput("SurvivorBoost", {
		Default = tostring(SpeedSettings.SurvivorBoost),
		Numeric = true,
		Finished = true,
		Text = "Survivor Boost",
		Callback = function(Value)
			SpeedSettings.SurvivorBoost = tonumber(Value) or 1
		end,
	})

	LeftSpeedTab:AddInput("BeastBoost", {
		Default = tostring(SpeedSettings.BeastBoost),
		Numeric = true,
		Finished = true,
		Text = "Beast Boost",
		Callback = function(Value)
			SpeedSettings.BeastBoost = tonumber(Value) or 1
		end,
	})

	LeftSpeedTab:AddInput("RunnerBoost", {
		Default = tostring(SpeedSettings.RunnerBoost),
		Numeric = true,
		Finished = true,
		Text = "Runner Boost",
		Callback = function(Value)
			SpeedSettings.RunnerBoost = tonumber(Value) or 2
		end,
	})

	LeftSpeedTab:AddInput("FatigueBoost", {
		Default = tostring(SpeedSettings.FatigueBoost),
		Numeric = true,
		Finished = true,
		Text = "Fatigue Boost",
		Callback = function(Value)
			SpeedSettings.FatigueBoost = tonumber(Value) or 1
		end,
	})

	LeftSpeedTab:AddInput("CrawlBoost", {
		Default = tostring(SpeedSettings.CrawlBoost),
		Numeric = true,
		Finished = true,
		Text = "Crawl Boost",
		Callback = function(Value)
			SpeedSettings.CrawlBoost = tonumber(Value) or 2
		end,
	})

	LeftSpeedTab:AddDivider()
	LeftSpeedTab:AddLabel("Jump Power Settings")

	LeftSpeedTab:AddToggle("JumpPowerEnabled", {
		Text = "Enable Jump Power",
		Default = false,
		Callback = function(Value)
			SpeedSettings.JumpPowerEnabled = Value
			if not Value then
				-- Al apagar, devuelve el salto normal si el valor actual es el que puso el script
				local MyChar = player.Character
				local Hum = MyChar and MyChar:FindFirstChild("Humanoid")
				if Hum and SpeedSettings.LastAppliedJP and Hum.JumpPower == SpeedSettings.LastAppliedJP then
					Hum.JumpPower = 36
				end
				SpeedSettings.LastAppliedJP = nil
			end
		end,
	})

	LeftSpeedTab:AddInput("SurvivorJump", {
		Default = tostring(SpeedSettings.SurvivorJumpPower),
		Numeric = true,
		Finished = true,
		Text = "Survivor Jump Power",
		Callback = function(Value)
			SpeedSettings.SurvivorJumpPower = tonumber(Value) or 36
		end,
	})

	LeftSpeedTab:AddInput("BeastJump", {
		Default = tostring(SpeedSettings.BeastJumpPower),
		Numeric = true,
		Finished = true,
		Text = "Beast Jump Power",
		Callback = function(Value)
			SpeedSettings.BeastJumpPower = tonumber(Value) or 36
		end,
	})

	local RightFatigueTab = Tabs["Danger Settings"]:AddRightTabbox("Fatigue Settings")
	local FatigueTab = RightFatigueTab:AddTab("Fatigue")

	FatigueTab:AddToggle("UseFatigueCheats", {
		Text = "Enable Fatigue Cheats",
		Default = false,
		Callback = function(Value)
			SpeedSettings.UseFatigueCheats = Value
		end,
	})

	FatigueTab:AddInput("FatigueDelay", {
		Default = tostring(SpeedSettings.FatigueDelay or 0),
		Numeric = true,
		Finished = true,
		Text = "Fatigue Delay (seconds)",
		Callback = function(Value)
			SpeedSettings.FatigueDelay = tonumber(Value) or 0
		end,
	})

	FatigueTab:AddInput("FatigueDuration", {
		Default = tostring(SpeedSettings.FatigueDuration or 0.8),
		Numeric = true,
		Finished = true,
		Text = "Fatigue Duration (seconds)",
		Callback = function(Value)
			SpeedSettings.FatigueDuration = tonumber(Value) or 0.8
		end,
	})

	local FlopHelperTab = Tabs["Danger Settings"]:AddLeftTabbox("Flop Helper")
	local FlopTab = FlopHelperTab:AddTab("Flop Settings")

	FlopTab:AddToggle("EnableFlopHelper", {
		Text = "Enable Flop Helper",
		Default = false,
		Callback = function(Value)
			FlopSettings.Enabled = Value
			if Value then
				StartFlopHelper()
			else
				StopFlopHelper()
			end
		end,
	})

	FlopTab:AddSlider("FlopDelay", {
		Default = 1.5,
		Min = 0.1,
		Max = 5,
		Rounding = 2,
		Text = "Flop Delay",
		Callback = function(Value)
			FlopSettings.Delay = Value
		end,
	})

	FlopTab:AddSlider("FlopX", {
		Default = 1,
		Min = -5,
		Max = 5,
		Rounding = 1,
		Text = "X Direction",
		Callback = function(Value)
			FlopSettings.XMultiplier = Value
		end,
	})

	FlopTab:AddSlider("FlopY", {
		Default = 0,
		Min = -5,
		Max = 5,
		Rounding = 1,
		Text = "Y Direction",
		Callback = function(Value)
			FlopSettings.YMultiplier = Value
		end,
	})

	FlopTab:AddSlider("FlopZ", {
		Default = 1,
		Min = -5,
		Max = 5,
		Rounding = 1,
		Text = "Z Direction",
		Callback = function(Value)
			FlopSettings.ZMultiplier = Value
		end,
	})
end

local CrosshairTab = Tabs.Crosshair:AddLeftTabbox("Crosshair Settings"):AddTab("Crosshair Settings")

CrosshairTab:AddToggle("CrosshairEnabled", {
	Text = "Enable Crosshair",
	Default = false,
	Callback = function(Value)
		CrosshairSettings.Enabled = Value
		CreateCrosshair()
	end,
})

CrosshairTab:AddDropdown("CrosshairType", {
	Values = CrosshairSettings.Order,
	Default = CrosshairSettings.Type,
	Text = "Crosshair Type",
	Callback = function(Value)
		SetCrosshairType(Value)
	end,
})

CrosshairTab:AddToggle("CrosshairUseColor", {
	Text = "Use Custom Color",
	Default = false,
	Callback = function(Value)
		CrosshairSettings.UseColor = Value
		UpdateCrosshair()
	end,
})

CrosshairTab:AddLabel("Crosshair Color"):AddColorPicker("CrosshairColor", {
	Default = CrosshairSettings.Color,
	Title = "Crosshair Color",
	Callback = function(Value)
		CrosshairSettings.Color = Value
		UpdateCrosshair()
	end,
})

CrosshairTab:AddSlider("CrosshairSize", {
	Default = CrosshairSettings.Types[CrosshairSettings.Type].Slider,
	Min = 1,
	Max = 100,
	Rounding = 0,
	Text = "Size",
	Callback = function(Value)
		-- El hub muestra 1 a 100; cada tipo lo convierte a sus propios pixeles
		CrosshairSettings.Types[CrosshairSettings.Type].Slider = Value
		UpdateCrosshair()
	end,
})

ExitFillPicker = Groupboxes.EspCustomization.PcAndTube:AddLabel("Exit Fill"):AddColorPicker("ExitFillPicker", {
	Default = Settings.EspSettings.ExitEsp.FillColor,
	Title = "Adjust exit fill",
	Transparency = Settings.EspSettings.ExitEsp.FillTransparency,
	Callback = function(value)
		Settings.EspSettings.ExitEsp.FillColor = value
		Settings.EspSettings.ExitEsp.FillTransparency = Options.ExitFillPicker.Transparency
		UpdateExitEspColors()
	end,
})

ExitOutlinePicker = Groupboxes.EspCustomization.PcAndTube:AddLabel("Exit Outline"):AddColorPicker("ExitOutlinePicker", {
	Default = Settings.EspSettings.ExitEsp.OutlineColor,
	Title = "Adjust exit outline",
	Transparency = Settings.EspSettings.ExitEsp.OutlineTransparency,
	Callback = function(value)
		Settings.EspSettings.ExitEsp.OutlineColor = value
		Settings.EspSettings.ExitEsp.OutlineTransparency = Options.ExitOutlinePicker.Transparency
		UpdateExitEspColors()
	end,
})

BushToggle = Groupboxes.Visual.LeftGroupBox:AddToggle("BushVisibility", {
	Text = "Remove Bushes",
	Default = false,
	Callback = function(Value)
		BushSettings.Enabled = Value
		if Value then
			EnableBushes()
		else
			DisableBushes()
		end
	end,
})

ShadowToggle = Groupboxes.Visual.LeftGroupBox:AddToggle("ShadowVisibility", {
	Text = "Remove Shadows",
	Default = false,
	Callback = function(Value)
		ShadowSettings.Enabled = Value
		if Value then
			DisableShadows()
		else
			EnableShadows()
		end
	end,
})

local RopeHelperTab = Tabs["Danger Settings"]:AddRightTabbox("Rope Helper")
local RopeTab = RopeHelperTab:AddTab("Rope Settings")

RopeTab:AddToggle("EnableRopeHelper", {
	Text = "Enable Rope Helper",
	Default = false,
	Callback = function(Value)
		RopeHelperSettings.Enabled = Value
	end,
})

RopeTab:AddToggle("RandomizePart", {
	Text = "Randomize Roped Part",
	Default = false,
	Callback = function(Value)
		RopeHelperSettings.RandomizePart = Value
	end,
})

RopeTab:AddDropdown("RopePartSelection", {
	Values = { "Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg" },
	Default = "Torso",
	Text = "Select Part to Rope",
	Callback = function(Value)
		RopeHelperSettings.SelectedPart = Value
	end,
})

RopeTab:AddToggle("AutoRopeOnHit", {
	Text = "Auto Rope on Hit",
	Default = false,
	Callback = function(Value)
		RopeHelperSettings.AutoRopeOnHit = Value
	end,
})

RopeTab:AddToggle("ClickToRope", {
	Text = "Click to Rope Nearest",
	Default = false,
	Callback = function(Value)
		RopeHelperSettings.ClickToRope = Value
	end,
})

RopeTab:AddSlider("RopeMaxDistance", {
	Default = 30,
	Min = 10,
	Max = 100,
	Rounding = 1,
	Text = "Max Rope Distance",
	Callback = function(Value)
		RopeHelperSettings.MaxDistance = Value
	end,
})

-- AUTO TIE CROSSHAIR — lógica exacta del archivo auto_tie_at_crosshair.txt
local _atcEnabled = false
local _atcDistance = 15
local _atcSensitivity = 0.85

local _atcThread = nil
local _atcHammer = nil

local function ATCStep()
	do
		pcall(function()
			local myChar = player.Character
			if not myChar then return end
			local myHRP = myChar:FindFirstChild("HumanoidRootPart")
				or myChar:FindFirstChild("Torso")
			if not myHRP then return end
			-- HammerEvent en cache (la busqueda recursiva solo se repite si cambio el personaje)
			if not _atcHammer or not _atcHammer:IsDescendantOf(myChar) then
				_atcHammer = myChar:FindFirstChild("HammerEvent", true)
			end
			local hammerEvent = _atcHammer
			if not hammerEvent then return end
			local cam = workspace.CurrentCamera
			for _, tgt in pairs(Players:GetPlayers()) do
				if tgt ~= player and tgt.Character then
					local stats = tgt:FindFirstChild("TempPlayerStatsModule")
					if stats then
						local ragdoll = stats:FindFirstChild("Ragdoll")
						local captured = stats:FindFirstChild("Captured")
						if ragdoll and captured
							and ragdoll.Value == true
							and captured.Value == false then
							local tHRP = tgt.Character:FindFirstChild("HumanoidRootPart")
								or tgt.Character:FindFirstChild("Torso")
								or tgt.Character:FindFirstChild("UpperTorso")
							if tHRP then
								local dist = (tHRP.Position - myHRP.Position).Magnitude
								local dir = (tHRP.Position - cam.CFrame.Position).Unit
								local dot = cam.CFrame.LookVector:Dot(dir)
								if dist <= _atcDistance and dot >= _atcSensitivity then
									pcall(function()
										hammerEvent:FireServer("HammerTieUp", tHRP, tHRP.Position)
									end)
								end
							end
						end
					end
				end
			end
		end)
	end
end

local function ATCStart()
	if _atcThread then return end
	_atcThread = task.spawn(function()
		while _atcEnabled do
			ATCStep()
			task.wait(0.1)
		end
		_atcThread = nil
	end)
end

RopeTab:AddDivider()

RopeTab:AddToggle("AutoTieCrosshair", {
	Text = "Auto Tie Crosshair",
	Default = false,
	Callback = function(Value)
		_atcEnabled = Value
		if Value then
			ATCStart()
		end
	end,
})

RopeTab:AddSlider("ATCDistance", {
	Default = 15,
	Min = 5,
	Max = 50,
	Rounding = 0,
	Text = "ATC Max Distance",
	Callback = function(Value)
		_atcDistance = Value
	end,
})

RopeTab:AddSlider("ATCSensitivity", {
	Default = 85,
	Min = 50,
	Max = 100,
	Rounding = 0,
	Text = "ATC Sensitivity (÷100)",
	Callback = function(Value)
		_atcSensitivity = Value / 100
	end,
})

local KillAuraTab = Tabs["Danger Settings"]:AddRightTabbox("Kill Aura")
local KATab = KillAuraTab:AddTab("Kill Aura")

KATab:AddToggle("EnableKillAura", {
	Text = "Enable Kill Aura",
	Default = false,
	Callback = function(Value)
		KillAuraSettings.Enabled = Value
		if Value then
			StartKillAura()
		else
			if KillAuraSettings.Connection then
				KillAuraSettings.Connection:Disconnect()
			end
		end
	end,
}):AddKeyPicker(
	"KillAuraKey",
	{ Default = "None", SyncToggleState = true, Mode = "Toggle", Text = "Kill Aura", NoUI = false }
)

KATab:AddSlider("KillAuraDistance", {
	Default = 30,
	Min = 1,
	Max = 100,
	Rounding = 1,
	Text = "Max Hit Distance",
	Callback = function(Value)
		KillAuraSettings.MaxDistance = Value
	end,
})

-- ════════════════════════════════════════════════════
-- FAMILY HACKS
-- ════════════════════════════════════════════════════
local FamilyHacksGroup = Tabs["Danger Settings"]:AddLeftTabbox("Family Hacks"):AddTab("Family Hacks")
-- Surv Boost (independiente del Speed Settings)
SurvBoostSettings = { Enabled = false, Value = 1, Conn = nil }

do
	FamilyHacksGroup:AddToggle("SurvBoostEnabled", {
		Text = "Enable Surv Boost",
		Default = false,
		Callback = function(Value)
			SurvBoostSettings.Enabled = Value
			if SurvBoostSettings.Conn then
				SurvBoostSettings.Conn:Disconnect()
				SurvBoostSettings.Conn = nil
			end
			if not Value then
				return
			end

			-- Solo existe mientras el toggle esta activado.
			-- Humanoid/HumanoidRootPart quedan en cache (solo se buscan al cambiar de personaje)
			-- y las comprobaciones baratas van primero para salir rapido cuando no hay boost.
			local cChar, cHum, cHrp = nil, nil, nil
			SurvBoostSettings.Conn = RunService.Stepped:Connect(function(_, deltaTime)
				local value = SurvBoostSettings.Value
				if value <= 0 then
					return
				end
				local char = Players.LocalPlayer.Character
				if not char then
					return
				end
				if char ~= cChar or not cHum or not cHrp then
					cChar = char
					cHum = char:FindFirstChild("Humanoid")
					cHrp = char:FindFirstChild("HumanoidRootPart")
					if not cHum or not cHrp then
						return
					end
				end
				local dir = cHum.MoveDirection
				if dir.Magnitude == 0 then
					return
				end
				local ws = cHum.WalkSpeed
				if ws < 15 or ws > 18 then
					return
				end
				if char:FindFirstChild("BeastPowers") then
					return
				end
				cHrp.CFrame = cHrp.CFrame + (dir * value * deltaTime)
			end)
		end,
	}):AddKeyPicker(
		"SurvBoostKey",
		{ Default = "None", SyncToggleState = true, Mode = "Toggle", Text = "Surv Boost", NoUI = false }
	)

	FamilyHacksGroup:AddInput("SurvBoostValue", {
		Default = "1",
		Numeric = true,
		Finished = true,
		Text = "Surv Boost",
		Callback = function(Value)
			SurvBoostSettings.Value = tonumber(Value) or 1
		end,
	})
end

FamilyHacksGroup:AddToggle("AutoTie", {
	Text = "Enable Auto Tie",
	Default = false,
	Callback = function(state)
		if state then
			local tying = false
			local currentTarget = nil
			local function isBeastStats()
				local stats = player:FindFirstChild("TempPlayerStatsModule")
				return stats and stats:FindFirstChild("IsBeast") and stats.IsBeast.Value
			end
			local function tiePlayer(targetChar)
				if tying then return end; tying = true
				local torso = targetChar:FindFirstChild("Torso") or targetChar:FindFirstChild("UpperTorso")
				local hrp = targetChar:FindFirstChild("HumanoidRootPart")
				if torso and hrp then
					pcall(function() player.Character.Hammer.HammerEvent:FireServer("HammerTieUp", torso, hrp.Position) end)
				end
				task.wait(0.15); tying = false
			end
			local function untiePlayer(targetChar)
				if tying then return end; tying = true
				local torso = targetChar:FindFirstChild("Torso") or targetChar:FindFirstChild("UpperTorso")
				local hrp = targetChar:FindFirstChild("HumanoidRootPart")
				if torso and hrp then
					pcall(function() player.Character.Hammer.HammerEvent:FireServer("HammerUntie", torso, hrp.Position) end)
				end
				task.wait(0.15); tying = false
			end
			local function setupHammer()
				local char = player.Character; if not char then return end
				local hammer = char:FindFirstChild("Hammer"); if not hammer then return end
				local handle = hammer:FindFirstChild("Handle"); if not handle then return end
				handle.Touched:Connect(function(hit)
					if not isBeastStats() then return end
					local targetChar = hit.Parent
					local tgtPlr = Players:GetPlayerFromCharacter(targetChar)
					if not tgtPlr or tgtPlr == player then return end
					local stats = tgtPlr:FindFirstChild("TempPlayerStatsModule"); if not stats then return end
					local rag = stats:FindFirstChild("Ragdoll"); if not rag then return end
					if rag.Value then
						if currentTarget == targetChar then
							untiePlayer(targetChar); currentTarget = nil
						else
							tiePlayer(targetChar); currentTarget = targetChar
						end
					end
				end)
			end
			if player.Character then setupHammer() end
			player.CharacterAdded:Connect(function()
				task.wait(1); currentTarget = nil; setupHammer()
			end)
		end
	end,
})

do
	-- Runner Jump Decendencia: solo como Beast (BeastPowers) y solo mientras gastas Runner.
	-- Fuera de eso el salto queda exactamente como lo maneja el juego.
	local RunnerMin, RunnerMax = 20, 29 -- rango de WalkSpeed del Runner
	local SlowFactor = 0.5              -- 0.5 = va a la mitad de velocidad
	local SlowTime = 0.2                -- segundos que dura la ralentizacion
	local LandWindow = 3                -- si no aterriza en 3 s, el salto se descarta
	local FallbackJump = 36             -- salto normal si no se pudo leer el del juego

	local RJ = {
		Enabled = false,
		Value = 30,      -- altura del salto con Runner (slider "Runner Jump Power")
		Conns = {},
		CharConn = nil,
		Restore = nil,
		Refresh = nil,
		Gen = 0,
	}

	local function Teardown()
		for _, c in ipairs(RJ.Conns) do
			pcall(function() c:Disconnect() end)
		end
		RJ.Conns = {}
		RJ.Refresh = nil
		if RJ.Restore then
			pcall(RJ.Restore)
			RJ.Restore = nil
		end
	end

	local function Setup(char, gen)
		Teardown()
		if not RJ.Enabled or not char then return end
		local Humanoid = char:WaitForChild("Humanoid", 5)
		if not Humanoid or not RJ.Enabled or gen ~= RJ.Gen then return end

		local beastPowers = char:FindFirstChild("BeastPowers") -- en cache, sin buscar en cada cambio
		local normalJump = nil         -- salto NORMAL del juego (solo valores > 0 y fuera de Runner)
		local gameUseJP = nil          -- UseJumpPower original del juego
		local applied = nil            -- ultimo JumpPower que pusimos nosotros
		local boosted = false          -- true mientras gastas Runner
		local jumpedWithRunner = false -- true solo entre el salto con Runner y el aterrizaje
		local jumpTime = 0
		local slowed = false
		local slowUntil = 0
		local slowSpeed = nil
		local normalSpeed = 0
		local token = 0
		local updating = false

		-- Devuelve el salto al valor del juego (solo si el que esta puesto es el nuestro)
		local function Release()
			if not boosted then return end
			boosted = false
			if Humanoid.Parent then
				-- Si el salto puesto sigue siendo el nuestro, lo devolvemos a uno NORMAL (nunca 0).
				-- Si el juego ya lo cambio por su cuenta, no se toca.
				if applied ~= nil and Humanoid.JumpPower == applied then
					Humanoid.JumpPower = normalJump or FallbackJump
				end
				if gameUseJP ~= nil then
					Humanoid.UseJumpPower = gameUseJP
				end
			end
			applied = nil
		end

		local function Update()
			if not Humanoid.Parent or updating then return end
			-- Seguro anti-trabado: si el frenado se quedo pegado, se suelta solo
			if slowed and os.clock() > slowUntil + 0.5 then
				slowed = false
				if slowSpeed and Humanoid.WalkSpeed == slowSpeed then
					Humanoid.WalkSpeed = normalSpeed
				end
			end
			if slowed then return end
			updating = true

			local jp = Humanoid.JumpPower
			local ws = Humanoid.WalkSpeed
			local isRunner = beastPowers ~= nil and ws >= RunnerMin and ws <= RunnerMax

			-- Recordamos el salto normal del juego. Durante el Runner el juego lo pone en 0,
			-- asi que ahi NO se guarda; tampoco se guarda nunca un 0.
			if not isRunner and jp ~= applied and jp > 0 then
				normalJump = jp
			end

			if isRunner then
				if not boosted then
					boosted = true
					gameUseJP = Humanoid.UseJumpPower
				end
				local target = RJ.Value
				if jp ~= target then
					Humanoid.UseJumpPower = true
					Humanoid.JumpPower = target
				end
				applied = target
			elseif boosted then
				Release()
			end

			updating = false
		end

		RJ.Refresh = Update

		RJ.Restore = function()
			token = token + 1
			if slowed then
				slowed = false
				if slowSpeed and Humanoid.Parent and Humanoid.WalkSpeed == slowSpeed then
					Humanoid.WalkSpeed = normalSpeed
				end
			end
			Release()
			jumpedWithRunner = false
		end

		table.insert(RJ.Conns, Humanoid.StateChanged:Connect(function(_, newState)
			-- salto: solo cuenta si lo hiciste gastando Runner
			if newState == Enum.HumanoidStateType.Jumping then
				jumpedWithRunner = boosted
				jumpTime = os.clock()
				return
			end

			-- en el aire no se toca la marca
			if newState == Enum.HumanoidStateType.Freefall then
				return
			end

			-- al caer de ese salto con Runner: frena un momento
			if newState == Enum.HumanoidStateType.Landed and jumpedWithRunner then
				jumpedWithRunner = false
				if os.clock() - jumpTime > LandWindow then return end

				if not slowed then
					slowed = true
					normalSpeed = Humanoid.WalkSpeed
				end
				slowSpeed = normalSpeed * SlowFactor
				slowUntil = os.clock() + SlowTime
				Humanoid.WalkSpeed = slowSpeed

				token = token + 1
				local myToken = token
				task.delay(SlowTime, function()
					if myToken ~= token then return end
					if Humanoid.Parent and Humanoid.WalkSpeed == slowSpeed then
						Humanoid.WalkSpeed = normalSpeed
					end
					slowed = false
					Update()
				end)
				return
			end

			-- cualquier otro estado (correr, trepar, sentarse, morir...) cancela la marca
			jumpedWithRunner = false
		end))

		-- Mantiene en cache si tienes o no BeastPowers
		table.insert(RJ.Conns, char.ChildAdded:Connect(function(c)
			if c.Name == "BeastPowers" then
				beastPowers = c
				Update()
			end
		end))
		table.insert(RJ.Conns, char.ChildRemoved:Connect(function(c)
			if c == beastPowers then
				beastPowers = nil
				Update()
			end
		end))

		table.insert(RJ.Conns, Humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(Update))
		table.insert(RJ.Conns, Humanoid:GetPropertyChangedSignal("JumpPower"):Connect(Update))
		Update()
	end

	FamilyHacksGroup:AddToggle("RunnerJumpDecendencia", {
		Text = "Runner Jump Decendencia",
		Default = false,
		Callback = function(v)
			RJ.Enabled = v
			RJ.Gen = RJ.Gen + 1
			local gen = RJ.Gen
			if RJ.CharConn then
				RJ.CharConn:Disconnect()
				RJ.CharConn = nil
			end
			if v then
				RJ.CharConn = player.CharacterAdded:Connect(function(char)
					RJ.Gen = RJ.Gen + 1
					local g = RJ.Gen
					task.spawn(Setup, char, g)
				end)
				if player.Character then
					task.spawn(Setup, player.Character, gen)
				end
			else
				Teardown()
			end
		end,
	})

	FamilyHacksGroup:AddSlider("RunnerJumpPower", {
		Text = "Runner Jump Power",
		Default = 30,
		Min = 20,
		Max = 40,
		Rounding = 0,
		Callback = function(value)
			RJ.Value = value
			if RJ.Refresh then
				RJ.Refresh()
			end
		end,
	})
end

-- HITBOX en Family Hacks
do
local _hitboxEnabled = false
local _hitboxSides = 6.5   -- lados (ancho, eje X)
local _hitboxFront = 6.5   -- frente / atras (profundidad, eje Z)
local _hitboxUpDown = 6.5  -- abajo / arriba (alto, eje Y)
local _hitboxTransparency = 0.5
local _hitboxConn = nil
local _hitboxAcc = 0

local function GetHitboxVector()
	return Vector3.new(_hitboxSides, _hitboxUpDown, _hitboxFront)
end

local _hitboxOrigCollide = setmetatable({}, { __mode = "k" })

local function HitboxNeedsUpdate(hrp, size)
	-- Comparacion con tolerancia: Transparency/Size se guardan como float32,
	-- asi que comparar con "~=" daba siempre "distinto" y se reescribia sin parar.
	return (hrp.Size - size).Magnitude > 0.01 or math.abs(hrp.Transparency - _hitboxTransparency) > 0.005
end

local function ApplyHitboxTo(plr)
	if plr == player then return end
	local char = plr.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	pcall(function()
		if _hitboxOrigCollide[hrp] == nil then
			_hitboxOrigCollide[hrp] = hrp.CanCollide
		end
		hrp.Size = GetHitboxVector()
		hrp.Transparency = _hitboxTransparency
		-- Un cubo gigante con colision es lo que mas pesa en la fisica del cliente
		hrp.CanCollide = false
	end)
end

local function ResetHitboxOf(plr)
	if plr == player then return end
	local char = plr.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	pcall(function()
		hrp.Size = Vector3.new(2, 2, 1)
		hrp.Transparency = 1
		local orig = _hitboxOrigCollide[hrp]
		if orig ~= nil then
			hrp.CanCollide = orig
			_hitboxOrigCollide[hrp] = nil
		end
	end)
end

local function ApplyHitboxAll()
	for _, v in pairs(Players:GetPlayers()) do
		ApplyHitboxTo(v)
	end
end

-- Mantiene el hitbox aplicado mientras esta activado (al correr, al reaparecer
-- o cuando entra un jugador nuevo el juego puede resetear el tamano).
-- Corre 4 veces por segundo y solo toca a quien realmente cambio.
local function StartHitboxLoop()
	if _hitboxConn then return end
	_hitboxAcc = 0
	_hitboxConn = RunService.Heartbeat:Connect(function(dt)
		_hitboxAcc = _hitboxAcc + dt
		if _hitboxAcc < 0.25 then return end
		_hitboxAcc = 0
		local size = GetHitboxVector()
		for _, v in pairs(Players:GetPlayers()) do
			if v ~= player then
				local char = v.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				if hrp and (HitboxNeedsUpdate(hrp, size) or hrp.CanCollide) then
					ApplyHitboxTo(v)
				end
			end
		end
	end)
end

local function StopHitboxLoop()
	if _hitboxConn then
		_hitboxConn:Disconnect()
		_hitboxConn = nil
	end
end

FamilyHacksGroup:AddToggle("HitBox", {
	Text = "Enable Hitbox",
	Default = false,
	Callback = function(state)
		_hitboxEnabled = state
		if state then
			ApplyHitboxAll()
			StartHitboxLoop()
		else
			StopHitboxLoop()
			for _, v in pairs(Players:GetPlayers()) do
				ResetHitboxOf(v)
			end
		end
	end,
}):AddKeyPicker("HitBoxKey", {
	Default = "None",
	SyncToggleState = true,
	Mode = "Toggle",
	Text = "Hitbox",
	NoUI = false,
})

-- Boton en pantalla (movil) para activar/desactivar Hitbox, igual que la keybind de PC
-- Solo existe mientras "Show on Screen" esta activado (sin GUI = sin costo).
do
	local Gui, Btn, Stroke

	-- rojo = desactivado, verde = activado
	local function Refresh()
		if not Btn then return end
		local on = Library.Toggles.HitBox and Library.Toggles.HitBox.Value
		Btn.BackgroundColor3 = on and Color3.fromRGB(30, 110, 30) or Color3.fromRGB(120, 25, 25)
		Stroke.Color = on and Color3.fromRGB(60, 200, 60) or Color3.fromRGB(200, 60, 60)
	end

	local function Build()
		if Gui then return end
		local old = CoreGui:FindFirstChild("HitboxScreenButtonGui")
		if old then old:Destroy() end

		Gui = Instance.new("ScreenGui")
		Gui.Name = "HitboxScreenButtonGui"
		Gui.ResetOnSpawn = false
		Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		if syn and syn.protect_gui then
			pcall(syn.protect_gui, Gui)
		end
		Gui.Parent = CoreGui

		Btn = Instance.new("TextButton")
		Btn.Name = "HitboxButton"
		Btn.Parent = Gui
		Btn.BackgroundTransparency = 0.2
		Btn.Position = UDim2.new(0, 20, 1, -200)
		Btn.Size = UDim2.new(0, 120, 0, 45)
		Btn.Font = Enum.Font.GothamBold
		Btn.Text = "HITBOX"
		Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		Btn.TextSize = 16
		Btn.AutoButtonColor = true

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = Btn

		Stroke = Instance.new("UIStroke")
		Stroke.Thickness = 2
		Stroke.Parent = Btn

		local drag = DragGui(Btn)
		Btn.MouseButton1Click:Connect(function()
			if drag.Moved then return end
			local t = Library.Toggles.HitBox
			if t then
				t:SetValue(not t.Value)
			end
		end)

		Refresh()
	end

	local function Remove()
		if Gui then
			Gui:Destroy()
			Gui, Btn, Stroke = nil, nil, nil
		end
	end

	Library.Toggles.HitBox:OnChanged(Refresh)

	FamilyHacksGroup:AddToggle("HitboxShowOnScreen", {
		Text = "Show on Screen",
		Default = false,
		Callback = function(Value)
			if Value then
				Build()
			else
				Remove()
			end
		end,
	})
end

FamilyHacksGroup:AddSlider("HitBoxSides", {
	Text = "Hitbox Lados (X)",
	Default = 6.5,
	Min = 1,
	Max = 30,
	Rounding = 1,
	Callback = function(value)
		_hitboxSides = value
		if _hitboxEnabled then
			ApplyHitboxAll()
		end
	end,
})

FamilyHacksGroup:AddSlider("HitBoxFront", {
	Text = "Hitbox Frente (Z)",
	Default = 6.5,
	Min = 1,
	Max = 30,
	Rounding = 1,
	Callback = function(value)
		_hitboxFront = value
		if _hitboxEnabled then
			ApplyHitboxAll()
		end
	end,
})

FamilyHacksGroup:AddSlider("HitBoxUpDown", {
	Text = "Hitbox Abajo/Arriba (Y)",
	Default = 6.5,
	Min = 1,
	Max = 30,
	Rounding = 1,
	Callback = function(value)
		_hitboxUpDown = value
		if _hitboxEnabled then
			ApplyHitboxAll()
		end
	end,
})

FamilyHacksGroup:AddSlider("HitBoxTransparency", {
	Text = "Hitbox Transparency",
	Default = 50,
	Min = 0,
	Max = 100,
	Rounding = 0,
	Callback = function(value)
		_hitboxTransparency = value / 100
		if _hitboxEnabled then
			ApplyHitboxAll()
		end
	end,
})
end

RainbowEspToggle = Groupboxes.Visual.RightGroupBox:AddToggle("RainbowEsp", {
	Text = "Rainbow ESP",
	Default = false,
	Callback = function(Value)
		RainbowEspState.Enabled = Value
		if Value then
			StartRainbowEsp()
		else
			StopRainbowEsp()
		end
	end,
})

RainbowSpeedSlider = Groupboxes.EspCustomization.PlayerEsp:AddSlider("RainbowSpeed", {
	Default = 0.1,
	Min = 0.1,
	Max = 5,
	Rounding = 1,
	Text = "Rainbow Speed",
	Callback = function(value)
		RainbowEspState.Speed = value
	end,
})

function ApplyFontToObject(obj)
	if not FontSettings.Enabled then
		return
	end
	if HasFontObject(obj) then
		obj.Font = FontSettings.SelectedFont
	end
end

function ApplyFontToContainer(container)
	for _, obj in ipairs(container:GetDescendants()) do
		ApplyFontToObject(obj)
	end
end

function StartFontChanger()
	if not FontSettings.Enabled then
		return
	end

	ApplyFontToContainer(playergui)

	table.insert(FontSettings.Connections, playergui.DescendantAdded:Connect(ApplyFontToObject))
end

function StopFontChanger()
	for _, conn in ipairs(FontSettings.Connections) do
		conn:Disconnect()
	end
	FontSettings.Connections = {}
end

GeneralCustomizationLeft = Tabs["General Customization"]:AddLeftTabbox("Fonts"):AddTab("Fonts")

GeneralCustomizationLeft:AddToggle("EnableFontChanger", {
	Text = "Enable Font Changer",
	Default = false,
	Callback = function(Value)
		FontSettings.Enabled = Value
		if Value then
			StartFontChanger()
		else
			StopFontChanger()
		end
	end,
})

GeneralCustomizationLeft:AddDropdown("FontSelection", {
	Values = {
		"SourceSans",
		"SourceSansBold",
		"SourceSansItalic",
		"SourceSansSemibold",
		"GothamBold",
		"AmaticSC",
		"Creepster",
		"DenkOne",
		"Fondamento",
		"FredokaOne",
		"Highway",
		"Kalam",
		"Merriweather",
		"PatrickHand",
		"RobotoMono",
	},
	Default = "SourceSans",
	Text = "Select Font",
	Callback = function(Value)
		FontSettings.SelectedFont = Enum.Font[Value]
		if FontSettings.Enabled then
			ApplyFontToContainer(playergui)
		end
	end,
})

GeneralCustomizationRight = Tabs["General Customization"]:AddRightTabbox("Gamma"):AddTab("Gamma")

GeneralCustomizationRight:AddLabel("Black Fog Gamma")

GeneralCustomizationRight:AddToggle("EnableBlackFogGamma", {
	Text = "Enable Gamma Adjustment",
	Default = false,
	Callback = function(Value)
		BlackFogGammaSettings.Enabled = Value
		if Value then
			StartBlackFogGamma()
		else
			StopBlackFogGamma()
			-- Si Black Fog sigue prendido, vuelve su gamma 1.11
			if BlackFogGammaSettings.FogAuto and Lighting:FindFirstChild("BlackFogConfig") then
				BlackFogGamma_Auto(true)
			end
		end
	end,
})

GeneralCustomizationRight:AddSlider("GammaValue", {
	Default = 1,
	Min = 0.1,
	Max = 3,
	Rounding = 2,
	Text = "Gamma Value",
	Callback = function(Value)
		BlackFogGammaSettings.GammaValue = Value
		UpdateBlackFogGamma()
	end,
})

-- ============================================================
-- GENERAL CUSTOMIZATION > No Sky Visuals
-- Quita los efectos visuales de Lighting (Bloom, DepthOfField, SunRays, ColorCorrection del juego,
-- Atmosphere) y TODOS los ajustes del Sky (cuerpos celestes, estrellas, skybox, sol y luna).
--   * NO borra nada: guarda los valores originales y al apagarlo los devuelve.
--   * Black Fog: si esta prendido, su Atmosphere NO se toca (queda funcionando solo eso).
--   * Boost Game: se combinan sin pelearse (se comparten los valores originales).
--   * Tus propios efectos (Gamma, Color Correction / Bloom de Shaders) NO se tocan.
--   * Sin bucles ni Heartbeat: solo eventos, y como maximo 1 correccion cada 0.25 s,
--     escribiendo unicamente lo que de verdad cambio (cero lag / cero bajada de FPS).
-- ============================================================
NoSkyVisuals = { Saved = nil, Conns = {}, Pending = false, Last = 0 }

do
	local GAP = 0.25
	local Reapply
	local Terrain = workspace:FindFirstChildOfClass("Terrain")

	local SKY_PROPS = {
		CelestialBodiesShown = false,
		StarCount = 0,
		SkyboxBk = "",
		SkyboxDn = "",
		SkyboxFt = "",
		SkyboxLf = "",
		SkyboxRt = "",
		SkyboxUp = "",
		SunTextureId = "",
		MoonTextureId = "",
	}
	local ATM_PROPS = { Density = 0, Haze = 0, Glare = 0 }
	local ENABLED_OFF = { Enabled = false }

	-- Efectos propios del script (gamma, shaders): no se tocan
	local function IsOwn(inst)
		local n = inst.Name
		return n == "BlackFogGammaCorrection" or n:sub(1, 3) == "BST"
	end

	-- Valor original real (si Boost Game ya lo cambio, se usa el que Boost guardo)
	local function OrigValue(inst, prop)
		local bs = IsBoosting() and BoostGame.Saved
		local e = bs and bs.Effects[inst]
		if e and e[1] == prop then
			return e[2]
		end
		return inst[prop]
	end

	local function Hook(saved, inst)
		if saved.Hooked[inst] then
			return
		end
		saved.Hooked[inst] = true
		table.insert(NoSkyVisuals.Conns, inst.Changed:Connect(Reapply))
	end

	local function Handle(saved, inst)
		if IsOwn(inst) then
			return
		end
		local target
		if inst:IsA("PostEffect") or inst:IsA("Clouds") then
			target = ENABLED_OFF
		elseif inst:IsA("Sky") then
			target = SKY_PROPS
		elseif inst:IsA("Atmosphere") then
			-- Black Fog manda sobre la Atmosphere: se vigila pero no se toca mientras este prendido
			Hook(saved, inst)
			if Lighting:FindFirstChild("BlackFogConfig") then
				return
			end
			target = ATM_PROPS
		else
			return
		end

		local rec = saved.Props[inst]
		if not rec then
			rec = {}
			saved.Props[inst] = rec
			for prop in pairs(target) do
				local ok, v = pcall(OrigValue, inst, prop)
				if ok then
					rec[prop] = v
				end
			end
			Hook(saved, inst)
		end

		for prop, want in pairs(target) do
			if rec[prop] ~= nil then
				pcall(function()
					if inst[prop] ~= want then
						inst[prop] = want
					end
				end)
			end
		end
	end

	local function ApplyAll(saved)
		for _, child in ipairs(Lighting:GetChildren()) do
			Handle(saved, child)
		end
		if Terrain then
			for _, child in ipairs(Terrain:GetChildren()) do
				if child:IsA("Clouds") then
					Handle(saved, child)
				end
			end
		end
	end

	Reapply = function()
		if NoSkyVisuals.Pending or not NoSkyVisuals.Saved then
			return
		end
		NoSkyVisuals.Pending = true
		local function run()
			NoSkyVisuals.Pending = false
			NoSkyVisuals.Last = os.clock()
			local saved = NoSkyVisuals.Saved
			if saved then
				pcall(ApplyAll, saved)
			end
		end
		local wait = GAP - (os.clock() - NoSkyVisuals.Last)
		if wait > 0 then
			task.delay(wait, run)
		else
			task.defer(run)
		end
	end

	function NoSkyVisuals.Start()
		if NoSkyVisuals.Saved then
			return
		end
		local saved = {
			Props = setmetatable({}, { __mode = "k" }),
			Hooked = setmetatable({}, { __mode = "k" }),
		}
		NoSkyVisuals.Saved = saved
		pcall(ApplyAll, saved)

		table.insert(
			NoSkyVisuals.Conns,
			Lighting.ChildAdded:Connect(function(child)
				if NoSkyVisuals.Saved then
					pcall(Handle, NoSkyVisuals.Saved, child)
				end
			end)
		)
		if Terrain then
			table.insert(
				NoSkyVisuals.Conns,
				Terrain.ChildAdded:Connect(function(child)
					if NoSkyVisuals.Saved and child:IsA("Clouds") then
						pcall(Handle, NoSkyVisuals.Saved, child)
					end
				end)
			)
		end
	end

	function NoSkyVisuals.Stop()
		local saved = NoSkyVisuals.Saved
		if not saved then
			return
		end
		NoSkyVisuals.Saved = nil
		for i = #NoSkyVisuals.Conns, 1, -1 do
			NoSkyVisuals.Conns[i]:Disconnect()
			NoSkyVisuals.Conns[i] = nil
		end

		local config = Lighting:FindFirstChild("BlackFogConfig")
		local bs = IsBoosting() and BoostGame.Saved
		for inst, rec in pairs(saved.Props) do
			if inst.Parent then
				for prop, orig in pairs(rec) do
					pcall(function()
						-- Black Fog prendido: no se pisa su niebla; se corrige lo que restaurara al apagarse
						if inst:IsA("Atmosphere") and config then
							local v = config:FindFirstChild(prop)
							if v then
								v.Value = orig
							end
							return
						end
						-- Boost Game prendido: se actualiza lo que el guardo y el valor real lo deja el Boost
						local e = bs and bs.Effects[inst]
						if e and e[1] == prop then
							e[2] = orig
							return
						end
						inst[prop] = orig
					end)
				end
			end
		end
	end
end

-- ============================================================
-- GENERAL CUSTOMIZATION > Performance Unlock
-- Opcion segura (solo ajustes del cliente, todo en pcall, todo se restaura al apagar):
--   * FPS: sube el tope de FPS a 120 o mas (respeta el FPS Manager: si esta en LOW no lo toca).
--   * Network: IncomingReplicationLag = 0 (recibe los datos del servidor sin retraso artificial).
--   * Physics: AllowSleep activo y throttle automatico del motor (el motor decide, sin forzar).
-- No fuerza nada peligroso (no desactiva el throttle de fisicas ni baja calidad grafica), asi que
-- no da lag, no baja FPS y no causa crasheos.
-- ============================================================
PerfUnlock = { Saved = nil }

do
	local function SetCap(n)
		if type(setfpscap) == "function" then
			pcall(setfpscap, n)
			return true
		elseif type(set_fps_cap) == "function" then
			pcall(set_fps_cap, n)
			return true
		end
		return false
	end

	local function ManagerCap()
		if FPSSettings then
			return FPSSettings.IsLowFPS and FPSSettings.LowFPS or FPSSettings.HighFPS
		end
		return 60
	end

	function PerfUnlock.Start()
		if PerfUnlock.Saved then
			return
		end
		local saved = {}
		PerfUnlock.Saved = saved

		-- FPS
		if not (FPSSettings and FPSSettings.IsLowFPS) then
			saved.CapChanged = SetCap(math.max(ManagerCap(), 120))
		end

		-- Network
		pcall(function()
			local net = settings().Network
			saved.Lag = net.IncomingReplicationLag
			if net.IncomingReplicationLag ~= 0 then
				net.IncomingReplicationLag = 0
			end
		end)

		-- Physics
		pcall(function()
			local ph = settings().Physics
			saved.Sleep = ph.AllowSleep
			if not ph.AllowSleep then
				ph.AllowSleep = true
			end
		end)
		pcall(function()
			local ph = settings().Physics
			saved.Throttle = ph.PhysicsEnvironmentalThrottle
			if ph.PhysicsEnvironmentalThrottle ~= Enum.EnviromentalPhysicsThrottle.DefaultAuto then
				ph.PhysicsEnvironmentalThrottle = Enum.EnviromentalPhysicsThrottle.DefaultAuto
			end
		end)
	end

	function PerfUnlock.Stop()
		local saved = PerfUnlock.Saved
		if not saved then
			return
		end
		PerfUnlock.Saved = nil

		if saved.CapChanged then
			SetCap(ManagerCap())
		end
		pcall(function()
			if saved.Lag ~= nil then
				settings().Network.IncomingReplicationLag = saved.Lag
			end
		end)
		pcall(function()
			if saved.Sleep ~= nil then
				settings().Physics.AllowSleep = saved.Sleep
			end
		end)
		pcall(function()
			if saved.Throttle ~= nil then
				settings().Physics.PhysicsEnvironmentalThrottle = saved.Throttle
			end
		end)
	end
end

PerformanceTab = Tabs["General Customization"]:AddRightTabbox("Performance"):AddTab("Performance")

PerformanceTab:AddToggle("NoSkyVisuals", {
	Text = "No Sky Visuals",
	Default = false,
	Callback = function(Value)
		if Value then
			NoSkyVisuals.Start()
		else
			NoSkyVisuals.Stop()
		end
	end,
})

PerformanceTab:AddToggle("PerformanceUnlock", {
	Text = "FPS / Physics / Network Boost",
	Default = false,
	Callback = function(Value)
		if Value then
			PerfUnlock.Start()
		else
			PerfUnlock.Stop()
		end
	end,
})

pcall(function()
	Library:OnUnload(function()
		NoSkyVisuals.Stop()
		PerfUnlock.Stop()
	end)
end)

-- ============================================================
-- HIDE CHAT (del script Super Galaxy)
-- Sin bucles ni conexiones por frame: solo cambia el CoreGui del chat y la barra superior cuando
-- se activa el toggle o se presiona la keybind, asi que no afecta los FPS.
-- Si el script se descarga con el chat oculto, se vuelve a mostrar.
-- ============================================================
ChatHider = { Enabled = false, Hidden = false }

-- Antes cada F4 hacia SetCoreGuiEnabled del chat + cambiar TopBarApp.Enabled (la barra superior se
-- reconstruye entera) + crear un hilo nuevo. Al spamear F4 todo eso se repetia decenas de veces por
-- segundo y bajaba los FPS. Ahora:
--   * El primer F4 se aplica de inmediato (igual que antes).
--   * Si vuelves a apretar F4 antes de CHAT_THROTTLE segundos, solo se recuerda el estado final y se
--     aplica UNA vez al terminar esa ventana (no se aplica cada estado intermedio).
--   * No se vuelve a escribir un valor que ya esta puesto.
--   * TopBarApp se guarda en cache (ya no se busca ni se crea un hilo en cada F4).
-- Si lo quieres mas rapido o mas lento cambia CHAT_THROTTLE (0 = como antes, sin limite).
do
	local StarterGui = game:GetService("StarterGui")
	local CHAT_THROTTLE = 0.2
	local ChatCore = Enum.CoreGuiType.Chat
	local topInner = nil
	local waitingTop = false
	local lastApply = 0
	local trailing = false
	local wanted = true -- ultimo estado pedido (visible = true)
	local applied = true -- ultimo estado puesto de verdad

	local function SetTopBar(visible)
		if topInner and not topInner.Parent then
			topInner = nil
		end
		if not topInner then
			local outer = CoreGui:FindFirstChild("TopBarApp")
			topInner = outer and outer:FindFirstChild("TopBarApp") or nil
		end
		if topInner then
			if topInner.Enabled ~= visible then
				topInner.Enabled = visible
			end
		elseif not waitingTop then
			-- La barra todavia no existe: se espera igual que antes (maximo 3 s), un solo hilo a la vez,
			-- y al encontrarla se le pone el estado actual (no el de cuando se pidio)
			waitingTop = true
			task.spawn(function()
				pcall(function()
					local outer = CoreGui:WaitForChild("TopBarApp", 3)
					local inner = outer and outer:WaitForChild("TopBarApp", 3)
					if inner then
						topInner = inner
						if inner.Enabled ~= applied then
							inner.Enabled = applied
						end
					end
				end)
				waitingTop = false
			end)
		end
	end

	local function ApplyNow(visible)
		applied = visible
		pcall(function()
			if StarterGui:GetCoreGuiEnabled(ChatCore) ~= visible then
				StarterGui:SetCoreGuiEnabled(ChatCore, visible)
			end
		end)
		-- Barra superior (icono de Roblox, 3 rayas, icono del chat): se oculta el ScreenGui TopBarApp
		pcall(SetTopBar, visible)
	end

	-- force = true: se aplica de inmediato sin limite (toggle del menu y descarga del script)
	function ChatHider.Apply(visible, force)
		ChatHider.Hidden = not visible
		wanted = visible
		local now = os.clock()
		if force or now - lastApply >= CHAT_THROTTLE then
			lastApply = now
			ApplyNow(visible)
		elseif not trailing then
			trailing = true
			task.delay(lastApply + CHAT_THROTTLE - now, function()
				trailing = false
				lastApply = os.clock()
				ApplyNow(wanted)
			end)
		end
	end
end

ChatHiderTab = Tabs["General Customization"]:AddLeftTabbox("Hide Chat"):AddTab("Hide Chat")

ChatHiderTab:AddToggle("EnableChatHider", {
	Text = "Enable Hide Chat",
	Default = false,
	Callback = function(Value)
		ChatHider.Enabled = Value
		if Value then
			ChatHider.Apply(false, true)
		else
			ChatHider.Apply(true, true)
		end
	end,
})

ChatHiderTab:AddLabel("Chat Toggle Key"):AddKeyPicker("ChatHiderKey", {
	Default = "None",
	SyncToggleState = false,
	Mode = "Toggle",
	Text = "Chat Toggle Key",
	NoUI = false,
})

Options.ChatHiderKey:OnClick(function()
	if not ChatHider.Enabled then
		return
	end
	ChatHider.Apply(ChatHider.Hidden)
end)

pcall(function()
	Library:OnUnload(function()
		if ChatHider.Hidden then
			ChatHider.Apply(true, true)
		end
	end)
end)

SoundBoosterTab = Tabs["Sound Customization"]:AddLeftTabbox("Sounds")
SoundTab = SoundBoosterTab:AddTab("Sound Settings")

SoundTab:AddToggle("RemoveOwnStepsJumps", {
	Text = "Remove Steps & Jumps",
	Default = false,
	Tooltip = "Silencia tus pasos y saltos. Si lo prendes se apagan Custom Steps y Custom Jump.",
	Callback = function(Value)
		if Value then
			-- Exclusivo con los sonidos custom (los apaga primero para que restauren el sonido original)
			for _, name in ipairs({ "CustomStepsEnabled", "CustomJumpEnabled" }) do
				local t = Library.Toggles[name]
				if t and t.Value then
					t:SetValue(false)
				end
			end
			StartOwnStepJumpMute()
		else
			StopOwnStepJumpMute()
		end
	end,
})

-- ============================================================
-- REMOVE SOUNDWALL (SoundHitWall del Hammer)
-- Solo eventos: sin loops, sin Heartbeat/RenderStepped, sin GetDescendants.
-- Al apagarlo restaura los valores originales del sonido.
-- ============================================================
SoundWall = {
	Enabled = false,
	Conns = {},
	CharConn = nil,
	Orig = setmetatable({}, { __mode = "k" }),
	SoundId = "rbxassetid://220025689",
}

function SoundWall_Configure(sound)
	if not SoundWall.Enabled or not sound or not sound:IsA("Sound") then
		return
	end
	if not SoundWall.Orig[sound] then
		local o = {
			SoundId = sound.SoundId,
			Volume = sound.Volume,
			PlaybackSpeed = sound.PlaybackSpeed,
			Looped = sound.Looped,
		}
		pcall(function()
			o.Min = sound.RollOffMinDistance
			o.Max = sound.RollOffMaxDistance
		end)
		SoundWall.Orig[sound] = o
		-- Si el juego vuelve a poner su sonido, se corrige al instante (por evento)
		table.insert(SoundWall.Conns, sound:GetPropertyChangedSignal("SoundId"):Connect(function()
			if SoundWall.Enabled and sound.SoundId ~= SoundWall.SoundId then
				sound.SoundId = SoundWall.SoundId
			end
		end))
	end
	sound.SoundId = SoundWall.SoundId
	sound.Volume = 0.3
	sound.PlaybackSpeed = 1.1
	sound.Looped = false
	pcall(function()
		sound.RollOffMinDistance = 1
		sound.RollOffMaxDistance = 2
	end)
end

function SoundWall_HookHandle(handle)
	SoundWall_Configure(handle:FindFirstChild("SoundHitWall"))
	table.insert(SoundWall.Conns, handle.ChildAdded:Connect(function(child)
		if child.Name == "SoundHitWall" then
			SoundWall_Configure(child)
		end
	end))
end

function SoundWall_HookHammer(hammer)
	local handle = hammer:FindFirstChild("Handle")
	if handle then
		SoundWall_HookHandle(handle)
	end
	table.insert(SoundWall.Conns, hammer.ChildAdded:Connect(function(child)
		if child.Name == "Handle" and SoundWall.Enabled then
			SoundWall_HookHandle(child)
		end
	end))
end

function SoundWall_HookCharacter(char)
	local hammer = char:FindFirstChild("Hammer")
	if hammer then
		SoundWall_HookHammer(hammer)
	end
	-- El Hammer aparece cuando eres Beast: se detecta por evento, sin revisar en bucle
	table.insert(SoundWall.Conns, char.ChildAdded:Connect(function(child)
		if child.Name == "Hammer" and SoundWall.Enabled then
			SoundWall_HookHammer(child)
		end
	end))
end

function StartSoundWall()
	if SoundWall.Enabled then
		return
	end
	SoundWall.Enabled = true
	if player.Character then
		SoundWall_HookCharacter(player.Character)
	end
	SoundWall.CharConn = player.CharacterAdded:Connect(function(char)
		if SoundWall.Enabled then
			SoundWall_HookCharacter(char)
		end
	end)
end

function StopSoundWall()
	SoundWall.Enabled = false
	if SoundWall.CharConn then
		SoundWall.CharConn:Disconnect()
		SoundWall.CharConn = nil
	end
	for _, c in ipairs(SoundWall.Conns) do
		pcall(function() c:Disconnect() end)
	end
	SoundWall.Conns = {}
	for sound, o in pairs(SoundWall.Orig) do
		if sound and sound.Parent then
			pcall(function()
				sound.SoundId = o.SoundId
				sound.Volume = o.Volume
				sound.PlaybackSpeed = o.PlaybackSpeed
				sound.Looped = o.Looped
				if o.Min then sound.RollOffMinDistance = o.Min end
				if o.Max then sound.RollOffMaxDistance = o.Max end
			end)
		end
		SoundWall.Orig[sound] = nil
	end
end

SoundTab:AddToggle("RemoveSoundWall", {
	Text = "Remove SoundWall",
	Default = false,
	Callback = function(Value)
		if Value then
			StartSoundWall()
		else
			StopSoundWall()
		end
	end,
})

-- ============================================================
-- SOUND CUSTOMIZATION > Custom Sounds (Steps / Jump / Land / Get Up)
-- Misma tecnica del script que funciona: se cambia el SoundId/Volume de los Sound que Roblox
-- crea dentro del HumanoidRootPart (Running, Jumping, Landing, GettingUp).
-- Rendimiento: solo eventos (ChildAdded / Volume / SoundId), nada por frame. Apagado = 0 conexiones.
-- ============================================================
CustomSounds = {
	Library = {
		-- IDs que ya funcionan
		["Pasos Original"] = "rbxassetid://89746938623207",
		["Salto Nuevo"] = "rbxassetid://76693372307958",
		-- IDs de tu lista
		["Pasos NoChillies"] = "rbxassetid://131126425324787",
		["Pasos Danger"] = "rbxassetid://120617181743016",
		["Action Jump"] = "rbxassetid://117587528032937",
		["Action Jump (1)"] = "rbxassetid://89606961192578",
		["Action Jump (2)"] = "rbxassetid://127161362900172",
		["Action Jump 1"] = "rbxassetid://125830194623630",
		["Action Jump Land (1)"] = "rbxassetid://99681997296929",
		["Action Get Up"] = "rbxassetid://117583601496598",
		["Bros 2 Mmia"] = "rbxassetid://139981328668110",
	},
	Kinds = {},
}

function CustomSounds.NewKind(key, soundName, defaultChoice, defaultVolume)
	local kind = {
		SoundName = soundName, -- nombre del Sound dentro del HumanoidRootPart
		Enabled = false,
		Id = CustomSounds.Library[defaultChoice],
		Volume = defaultVolume,
		Conns = {}, -- conexiones del personaje actual (se limpian al reaparecer)
		CharConn = nil, -- CharacterAdded (solo mientras esta prendido)
		Orig = setmetatable({}, { __mode = "k" }), -- sound -> { SoundId, Volume } originales
	}
	CustomSounds.Kinds[key] = kind
	return kind
end

local function CustomSounds_ClearConns(kind)
	for _, c in ipairs(kind.Conns) do
		pcall(function() c:Disconnect() end)
	end
	kind.Conns = {}
end

local function CustomSounds_Apply(kind, sound)
	if not kind.Enabled or not sound or not sound:IsA("Sound") then
		return
	end
	if not kind.Orig[sound] then
		kind.Orig[sound] = { SoundId = sound.SoundId, Volume = sound.Volume }
		-- Igual que el script que funciona: si el volumen cambia, se vuelve a fijar
		table.insert(kind.Conns, sound:GetPropertyChangedSignal("Volume"):Connect(function()
			if kind.Enabled and sound.Volume ~= kind.Volume then
				sound.Volume = kind.Volume
			end
		end))
		table.insert(kind.Conns, sound:GetPropertyChangedSignal("SoundId"):Connect(function()
			if kind.Enabled and sound.SoundId ~= kind.Id then
				sound.SoundId = kind.Id
			end
		end))
	end
	sound.SoundId = kind.Id
	sound.Volume = kind.Volume
end

local function CustomSounds_HookCharacter(kind, char)
	task.spawn(function()
		local hrp = char:WaitForChild("HumanoidRootPart", 5)
		if not hrp or not kind.Enabled then
			return
		end
		CustomSounds_Apply(kind, hrp:FindFirstChild(kind.SoundName))
		table.insert(kind.Conns, hrp.ChildAdded:Connect(function(child)
			if kind.Enabled and child.Name == kind.SoundName then
				CustomSounds_Apply(kind, child)
			end
		end))
	end)
end

function CustomSounds.Start(kind)
	CustomSounds_ClearConns(kind)
	if kind.CharConn then
		kind.CharConn:Disconnect()
		kind.CharConn = nil
	end
	kind.Enabled = true
	if player.Character then
		CustomSounds_HookCharacter(kind, player.Character)
	end
	kind.CharConn = player.CharacterAdded:Connect(function(char)
		CustomSounds_ClearConns(kind)
		if kind.Enabled then
			CustomSounds_HookCharacter(kind, char)
		end
	end)
end

function CustomSounds.Stop(kind)
	kind.Enabled = false
	if kind.CharConn then
		kind.CharConn:Disconnect()
		kind.CharConn = nil
	end
	CustomSounds_ClearConns(kind)
	for sound, o in pairs(kind.Orig) do
		if sound and sound.Parent then
			pcall(function()
				sound.SoundId = o.SoundId
				sound.Volume = o.Volume
			end)
		end
		kind.Orig[sound] = nil
	end
end

function CustomSounds.SetChoice(kind, choice)
	local id = CustomSounds.Library[choice]
	if not id then
		return
	end
	kind.Id = id
	if kind.Enabled then
		for sound in pairs(kind.Orig) do
			if sound and sound.Parent then
				sound.SoundId = id
			end
		end
	end
end

function CustomSounds.SetVolume(kind, value)
	kind.Volume = value
	if kind.Enabled then
		for sound in pairs(kind.Orig) do
			if sound and sound.Parent then
				sound.Volume = value
			end
		end
	end
end

-- Arma toggle + dropdown + slider de un tipo de sonido dentro de un groupbox
local function CustomSounds_BuildUI(box, prefix, label, kind, values, tooltip, onEnable)
	box:AddToggle(prefix .. "Enabled", {
		Text = "Custom " .. label,
		Default = false,
		Tooltip = tooltip,
		Callback = function(Value)
			if Value then
				if onEnable then
					onEnable()
				end
				CustomSounds.Start(kind)
			else
				CustomSounds.Stop(kind)
			end
		end,
	})
	box:AddDropdown(prefix .. "Sound", {
		Values = values,
		Default = values[1],
		Text = label .. " Sound",
		Callback = function(Value)
			CustomSounds.SetChoice(kind, Value)
		end,
	})
	box:AddSlider(prefix .. "Volume", {
		Default = kind.Volume,
		Min = 0,
		Max = 3,
		Rounding = 2,
		Text = label .. " Volume",
		Callback = function(Value)
			CustomSounds.SetVolume(kind, Value)
		end,
	})
end

local function CustomSounds_DisableRemoveStepsJumps()
	local t = Library.Toggles.RemoveOwnStepsJumps
	if t and t.Value then
		t:SetValue(false)
	end
end

local CS_Steps = CustomSounds.NewKind("Steps", "Running", "Pasos Original", 0.3)
local CS_Jump = CustomSounds.NewKind("Jump", "Jumping", "Salto Nuevo", 0.3)
local CS_Land = CustomSounds.NewKind("Land", "Landing", "Action Jump Land (1)", 1)
local CS_GetUp = CustomSounds.NewKind("GetUp", "GettingUp", "Action Get Up", 1)

CustomSoundsTabBox = Tabs["Sound Customization"]:AddRightTabbox("Custom Sounds")
CustomStepsTab = CustomSoundsTabBox:AddTab("Steps")
CustomJumpTab = CustomSoundsTabBox:AddTab("Jump")
CustomLandGetUpTab = CustomSoundsTabBox:AddTab("Land / Get Up")

CustomSounds_BuildUI(
	CustomStepsTab,
	"CustomSteps",
	"Steps",
	CS_Steps,
	{ "Pasos Original", "Pasos NoChillies", "Pasos Danger", "Bros 2 Mmia" },
	"Cambia el sonido de tus pasos. Apaga Remove Steps & Jumps si estaba prendido.",
	CustomSounds_DisableRemoveStepsJumps
)

CustomSounds_BuildUI(
	CustomJumpTab,
	"CustomJump",
	"Jump",
	CS_Jump,
	{ "Salto Nuevo", "Action Jump", "Action Jump (1)", "Action Jump (2)", "Action Jump 1", "Bros 2 Mmia" },
	"Cambia el sonido de tu salto. Apaga Remove Steps & Jumps si estaba prendido.",
	CustomSounds_DisableRemoveStepsJumps
)

CustomLandGetUpTab:AddLabel("Landing")
CustomSounds_BuildUI(
	CustomLandGetUpTab,
	"CustomLand",
	"Land",
	CS_Land,
	{ "Action Jump Land (1)", "Bros 2 Mmia" },
	"Cambia el sonido al aterrizar de un salto."
)
CustomLandGetUpTab:AddDivider()
CustomLandGetUpTab:AddLabel("Get Up")
CustomSounds_BuildUI(
	CustomLandGetUpTab,
	"CustomGetUp",
	"Get Up",
	CS_GetUp,
	{ "Action Get Up", "Bros 2 Mmia" },
	"Cambia el sonido al levantarte."
)

pcall(function()
	Library:OnUnload(function()
		for _, kind in pairs(CustomSounds.Kinds) do
			if kind.Enabled then
				CustomSounds.Stop(kind)
			end
		end
	end)
end)

-- ============================================================
-- Detector de Beast compartido (ESP, Thirdp y Gem NoLight)
-- Usa EXACTAMENTE el mismo criterio que el ESP (ApplyHighlightColors) y que GetBeast():
-- un personaje es Beast si tiene "BeastPowers". Eso se mira con FindFirstChild solo cuando algo pudo
-- cambiar, nunca en bucle:
--   * entra o sale "BeastPowers" del personaje de CUALQUIER jugador (evento ChildAdded/ChildRemoved)
--   * alguien reaparece, entra o sale de la partida
--   * cambia IsGameActive (el mismo evento que usa el ESP)
-- Varios cambios en el mismo frame se juntan en UNA sola revision.
-- Solo hay conexiones mientras alguna opcion lo necesita; si no, 0 conexiones.
-- ============================================================
BeastWatch = {
	Subs = {}, -- [nombre] = funcion que se llama cuando cambia el estado de Beast
	Count = 0,
	Players = {}, -- [jugador] = { CharConn = conexion, ChildConns = { conexiones } }
	PlayerAddedConn = nil,
	PlayerRemovingConn = nil,
	GameConn = nil,
	Pending = false,
}

-- Mismo criterio que el ESP y GetBeast()
function BeastWatch.IsBeastChar(char)
	return char ~= nil and char:FindFirstChild("BeastPowers") ~= nil
end

-- Yo soy Beast
function BeastWatch.IsBeast()
	return BeastWatch.IsBeastChar(player.Character)
end

-- Personaje de la Beast actual (el mismo GetBeast() del ESP, sin duplicar logica)
function BeastWatch.GetBeastChar()
	return GetBeast()
end

local function BeastWatch_Notify()
	if BeastWatch.Pending then
		return
	end
	BeastWatch.Pending = true
	task.defer(function()
		BeastWatch.Pending = false
		local list = {}
		for _, fn in pairs(BeastWatch.Subs) do
			list[#list + 1] = fn
		end
		for i = 1, #list do
			local ok, err = pcall(list[i])
			if not ok then
				warn("BeastWatch:", err)
			end
		end
	end)
end

local function BeastWatch_UnhookPlayer(plr)
	local d = BeastWatch.Players[plr]
	if not d then
		return
	end
	BeastWatch.Players[plr] = nil
	if d.CharConn then
		d.CharConn:Disconnect()
	end
	for i = 1, #d.ChildConns do
		d.ChildConns[i]:Disconnect()
	end
end

local function BeastWatch_HookPlayer(plr)
	if BeastWatch.Players[plr] then
		return
	end
	local d = { CharConn = nil, ChildConns = {} }
	BeastWatch.Players[plr] = d

	local function onChild(child)
		if child.Name == "BeastPowers" then
			BeastWatch_Notify()
		end
	end

	local function hookChar(char)
		for i = #d.ChildConns, 1, -1 do
			d.ChildConns[i]:Disconnect()
			d.ChildConns[i] = nil
		end
		if not char then
			return
		end
		d.ChildConns[1] = char.ChildAdded:Connect(onChild)
		d.ChildConns[2] = char.ChildRemoved:Connect(onChild)
	end

	d.CharConn = plr.CharacterAdded:Connect(function(char)
		hookChar(char)
		BeastWatch_Notify()
	end)
	hookChar(plr.Character)
end

local function BeastWatch_Stop()
	for plr in pairs(BeastWatch.Players) do
		BeastWatch_UnhookPlayer(plr)
	end
	if BeastWatch.PlayerAddedConn then
		BeastWatch.PlayerAddedConn:Disconnect()
		BeastWatch.PlayerAddedConn = nil
	end
	if BeastWatch.PlayerRemovingConn then
		BeastWatch.PlayerRemovingConn:Disconnect()
		BeastWatch.PlayerRemovingConn = nil
	end
	if BeastWatch.GameConn then
		BeastWatch.GameConn:Disconnect()
		BeastWatch.GameConn = nil
	end
end

-- No llama a fn al suscribirse: quien se suscribe revisa el estado actual por su cuenta
function BeastWatch.Subscribe(name, fn)
	if BeastWatch.Subs[name] == nil then
		BeastWatch.Count = BeastWatch.Count + 1
	end
	BeastWatch.Subs[name] = fn
	if not BeastWatch.PlayerAddedConn then
		BeastWatch.PlayerAddedConn = Players.PlayerAdded:Connect(BeastWatch_HookPlayer)
		BeastWatch.PlayerRemovingConn = Players.PlayerRemoving:Connect(function(plr)
			BeastWatch_UnhookPlayer(plr)
			BeastWatch_Notify()
		end)
		pcall(function()
			local active = ReplicatedStorage:FindFirstChild("IsGameActive")
			if active then
				BeastWatch.GameConn = active.Changed:Connect(BeastWatch_Notify)
			end
		end)
		for _, plr in ipairs(Players:GetPlayers()) do
			BeastWatch_HookPlayer(plr)
		end
	end
end

function BeastWatch.Unsubscribe(name)
	if BeastWatch.Subs[name] == nil then
		return
	end
	BeastWatch.Subs[name] = nil
	BeastWatch.Count = BeastWatch.Count - 1
	if BeastWatch.Count <= 0 then
		BeastWatch.Count = 0
		BeastWatch_Stop()
	end
end

-- ============================================================
-- ADVANCED > Gem NoLight
-- Pone en 0 (solo en TU pantalla) el brillo de la luz PointLight de la gema de la Beast.
-- Detecta a la Beast como el ESP (cualquier jugador con "BeastPowers").
-- No hay bucles ni Heartbeat/RenderStepped: solo eventos.
--   * Al detectarse la Beast: UN escaneo de su personaje + 1 evento DescendantAdded sobre ese personaje
--     (si el juego crea otra luz, tambien se pone en 0).
--   * Apagado y sin Beast bloqueada = 0 conexiones y 0 codigo corriendo.
-- Una vez aplicado queda BLOQUEADO: apagar la opcion no devuelve la luz hasta que esa Beast deje de
-- serlo. Al terminar se devuelve el brillo original (se guarda un solo numero por luz).
-- ============================================================
-- true  = solo quita la luz cuando TU eres la Beast (la gema de otras Beasts NO se toca)
-- false = quita la luz de la Beast sea quien sea (tu o cualquier otro jugador)
local GEM_ONLY_ME = true

GemNoLight = {
	Enabled = false, -- estado del toggle
	Active = {}, -- [personaje Beast] = { Conn = DescendantAdded, Lights = { [luz] = { Brightness = original, ... } } }
}

-- Solo pone el brillo de la luz en 0 (en tu pantalla) y guarda el valor original: ya no se clona ni
-- se destruye nada (antes cada luz = 1 Clone + 1 Destroy; si el juego la recreaba habia basura y tirones).
local function GemNoLight_Kill(entry, inst)
	-- Check mas barato primero: casi todo lo que entra al personaje NO es un PointLight
	if inst.ClassName ~= "PointLight" then
		return
	end
	local lights = entry.Lights
	if lights[inst] ~= nil then
		return
	end
	local rec = { Brightness = inst.Brightness, Conn = nil, DestroyConn = nil }
	lights[inst] = rec
	if rec.Brightness ~= 0 then
		inst.Brightness = 0
	end
	-- Si el juego vuelve a subir el brillo, se anota lo que queria (para devolverlo al final) y se
	-- vuelve a poner en 0. Solo corre si el juego toca el brillo; si no lo toca, no hace nada.
	rec.Conn = inst:GetPropertyChangedSignal("Brightness"):Connect(function()
		local b = inst.Brightness
		if b ~= 0 then
			rec.Brightness = b
			inst.Brightness = 0
		end
	end)
	-- Si el juego destruye esa luz se suelta sola (no se acumulan luces muertas en la tabla)
	rec.DestroyConn = inst.Destroying:Connect(function()
		lights[inst] = nil
	end)
end

local function GemNoLight_Lock(char)
	if GemNoLight.Active[char] then
		return
	end
	local entry = { Conn = nil, Lights = {} }
	GemNoLight.Active[char] = entry
	-- Un unico escaneo al detectar la Beast (igual que IY; no es un loop)
	for _, d in ipairs(char:GetDescendants()) do
		GemNoLight_Kill(entry, d)
	end
	entry.Conn = char.DescendantAdded:Connect(function(d)
		GemNoLight_Kill(entry, d)
	end)
end

local function GemNoLight_Release(char)
	local entry = GemNoLight.Active[char]
	if not entry then
		return
	end
	GemNoLight.Active[char] = nil
	if entry.Conn then
		entry.Conn:Disconnect()
	end
	-- Devuelve el brillo original a las luces que siguen existiendo (si moriste y el personaje se fue,
	-- ya no hay nada que restaurar)
	for light, rec in pairs(entry.Lights) do
		if rec.Conn then
			rec.Conn:Disconnect()
		end
		if rec.DestroyConn then
			rec.DestroyConn:Disconnect()
		end
		if light.Parent ~= nil then
			light.Brightness = rec.Brightness
		end
	end
end

-- Se llama cuando cambia el estado de Beast (detector compartido BeastWatch)
local function GemNoLight_Update()
	-- Suelta lo que ya no es Beast o ya no existe (respawn, fin de ronda, jugador que se fue)
	for char in pairs(GemNoLight.Active) do
		if char.Parent == nil or not BeastWatch.IsBeastChar(char) then
			GemNoLight_Release(char)
		end
	end

	if GemNoLight.Enabled then
		local beast
		if GEM_ONLY_ME then
			beast = BeastWatch.IsBeast() and player.Character or nil
		else
			beast = BeastWatch.GetBeastChar()
		end
		if beast then
			GemNoLight_Lock(beast)
		end
	end

	-- Apagado y sin luz bloqueada: NO queda nada conectado ni corriendo
	if not GemNoLight.Enabled and next(GemNoLight.Active) == nil then
		BeastWatch.Unsubscribe("GemNoLight")
	end
end

AdvancedTabbox = Tabs["General Customization"]:AddLeftTabbox("Advanced")
AdvancedTab = AdvancedTabbox:AddTab("Advanced")

AdvancedTab:AddToggle("GemNoLight", {
	Text = "Gem NoLight",
	Default = false,
	Callback = function(Value)
		GemNoLight.Enabled = Value
		if Value then
			-- Se conecta SOLO al activar el toggle; si ya hay Beast, le quita la luz en el momento
			BeastWatch.Subscribe("GemNoLight", GemNoLight_Update)
			GemNoLight_Update()
		elseif next(GemNoLight.Active) ~= nil then
			-- No se puede revertir mientras siga siendo Beast; al terminar se limpia todo solo
			Library:Notify("Gem NoLight: la luz volvera cuando la Beast deje de serlo", 3)
		else
			BeastWatch.Unsubscribe("GemNoLight") -- apagado y sin luz bloqueada: se desconecta todo
		end
	end,
})

-- ============================================================
-- ADVANCED > Shiftlock (apagado por defecto) + keybind configurable
-- Funciona en PC y movil:
--   * Movil/PC: el personaje gira hacia donde mira la camara (RotationType = CameraRelative).
--   * PC: ademas bloquea el mouse en el centro (la camara se mueve solo con el mouse, sin
--     click derecho) y muestra la mira del shiftlock.
-- El toggle "Shiftlock" lo prende/apaga todo. Una vez prendido, se pone de una vez y
-- puedes pausarlo/reanudarlo con la keybind que configures al lado del toggle; si no pusiste
-- ninguna keybind, se usa unicamente la tecla C.
-- El boton "Show Shiftlock On Screen" (movil) solo sirve si el Shiftlock esta prendido.
-- Mientras el menu de BST esta abierto, mantienes Alt izquierdo o escribes en una caja de texto,
-- el mouse se suelta para poder usarlo; al terminar se vuelve a poner solo.
-- Optimizado: apagado = 0 conexiones y 0 bucles. Prendido en PC = 1 RenderStep que solo compara
-- valores + 1 evento de RotationType + 1 evento de teclado. Movil: los 2 eventos.
-- ============================================================
ShiftLock = {
	Enabled = false, -- toggle prendido (sistema armado)
	Active = false, -- shiftlock puesto en este momento
	OrigRot = nil,
	OrigIcon = true,
	Locked = false,
	RotConn = nil,
	RenderConn = nil,
	CharConn = nil,
	InputConn = nil,
	Crosshair = nil,
	Refresh = nil,
}

do
	local GameSettings = UserSettings():GetService("UserGameSettings")
	local BIND_NAME = "BSTShiftLock"
	local DEFAULT_KEY = Enum.KeyCode.C
	local FREE_KEY = Enum.KeyCode.LeftAlt
	local COL_OFF = Color3.fromRGB(180, 180, 180)
	local COL_ON = Color3.fromRGB(0, 140, 255)
	local CameraRelative = Enum.RotationType.CameraRelative
	local LockCenter = Enum.MouseBehavior.LockCenter
	local DefaultMouse = Enum.MouseBehavior.Default
	local guiParent = (gethui and gethui()) or CoreGui

	local function ApplyRotation()
		-- Importante: si ya se quito el shiftlock (aunque sea un task.defer pendiente) NO se vuelve a poner
		if not ShiftLock.Active then
			return
		end
		if GameSettings.RotationType ~= CameraRelative then
			GameSettings.RotationType = CameraRelative
		end
	end

	-- Zoom rapido (primera <-> tercera persona muchas veces seguidas): cada cambio de camara hace que el
	-- juego cambie RotationType y antes se volvia a escribir en el momento, una vez por cada cambio.
	-- Escribir UserGameSettings es caro y varias veces seguidas bajaba los FPS. Ahora esas escrituras se
	-- juntan: se espera ROT_SETTLE segundos sin nuevos cambios y se escribe UNA sola vez con el valor final.
	-- Si quieres que lo corrija mas rapido o mas lento, cambia ROT_SETTLE.
	local ROT_SETTLE = 0.1
	-- Antes cada cambio de RotationType creaba un hilo nuevo (task.delay); con zoom rapido eran decenas.
	-- Ahora hay UN solo hilo pendiente a la vez: guarda la hora del ultimo cambio y, si llegan mas
	-- cambios mientras espera, se vuelve a dormir lo que falte. Mismo resultado: se escribe una sola
	-- vez, ROT_SETTLE segundos despues del ultimo cambio.
	local rotLast = 0
	local rotPending = false
	local function RotCheck()
		local remaining = rotLast + ROT_SETTLE - os.clock()
		if remaining > 0 then
			task.delay(remaining, RotCheck)
		else
			rotPending = false
			ApplyRotation()
		end
	end
	local function QueueRotation()
		rotLast = os.clock()
		if not rotPending then
			rotPending = true
			task.delay(ROT_SETTLE, RotCheck)
		end
	end

	-- Misma logica del shiftlock_pc_movil.lua:
	-- PC: cada frame mantiene el mouse en LockCenter (la camara y el personaje giran con solo
	-- mover el mouse, sin click derecho) + RotationType CameraRelative. Movil: solo RotationType.
	-- Solo compara valores, sin lag. Apagado = 0 conexiones y 0 bucles.
	-- El personaje gira con la camara (como el script de referencia: root.CFrame mira hacia donde mira la camara).
	-- Humanoid y HumanoidRootPart quedan en cache; solo se buscan cuando cambia el personaje.
	local rotChar, rotHum, rotHrp = nil, nil, nil
	local autoRotOff = false
	-- Estados guardados una sola vez (antes se buscaban en Enum varias veces en cada frame)
	local ST_PHYSICS = Enum.HumanoidStateType.Physics
	local ST_RAGDOLL = Enum.HumanoidStateType.Ragdoll
	local ST_DEAD = Enum.HumanoidStateType.Dead
	local ST_SEATED = Enum.HumanoidStateType.Seated
	local ST_PLATFORM = Enum.HumanoidStateType.PlatformStanding

	-- AutoRotate = false mientras el shiftlock manda (si no, el humanoide gira al personaje hacia donde camina)
	local function SetAutoRotate(on)
		if on then
			if autoRotOff then
				autoRotOff = false
				if rotHum and rotHum.Parent then
					rotHum.AutoRotate = true
				end
			end
		elseif rotHum and rotHum.AutoRotate then
			rotHum.AutoRotate = false
			autoRotOff = true
		end
	end

	local function FaceCamera()
		local char = player.Character
		if char ~= rotChar then
			if autoRotOff and rotHum and rotHum.Parent then
				rotHum.AutoRotate = true
			end
			autoRotOff = false
			rotChar = char
			rotHum = char and char:FindFirstChildOfClass("Humanoid")
			rotHrp = char and char:FindFirstChild("HumanoidRootPart")
		end
		if not rotHum or not rotHrp or not rotHrp.Parent or rotHum.Health <= 0 then
			return
		end
		-- No molestar cuando estas tirado / en flop / sentado
		local state = rotHum:GetState()
		if state == ST_PHYSICS or state == ST_RAGDOLL or state == ST_DEAD or state == ST_SEATED or state == ST_PLATFORM then
			SetAutoRotate(true)
			return
		end
		local cam = workspace.CurrentCamera
		if not cam then
			return
		end
		SetAutoRotate(false)
		-- Giro (yaw) de la camara sacado del LookVector: da el mismo valor que ToEulerAnglesYXZ.
		-- Todo se hace con numeros sueltos (GetComponents): antes se creaban varios Vector3 y CFrames
		-- nuevos en cada frame; ahora no se crea ninguno (menos basura = menos tirones de FPS).
		-- LookVector = (-R02, -R12, -R22) | UpVector = (R01, R11, R21)
		local _, _, _, _, _, c02, _, _, _, _, _, c22 = cam.CFrame:GetComponents()
		local y = math.atan2(c02, c22) -- = atan2(-LookVector.X, -LookVector.Z)
		local sy, cy = math.sin(y), math.cos(y)
		local px, py, pz, _, u01, l02, _, u11, l12, _, u21, l22 = rotHrp.CFrame:GetComponents()
		-- Solo se escribe si la rotacion de verdad cambio (resultado identico, sin mover el personaje en cada frame)
		-- (Magnitude > 1e-5 es lo mismo que suma de cuadrados > 1e-10)
		local dx, dz = sy - l02, cy - l22
		local ex, ez = u11 - 1, u21
		if
			dx * dx + l12 * l12 + dz * dz > 1e-10
			or u01 * u01 + ex * ex + ez * ez > 1e-10
		then
			rotHrp.CFrame = CFrame.new(px, py, pz, cy, 0, sy, 0, 1, 0, -sy, 0, cy)
		end
	end

	-- Mira del shiftlock: se crea / se quita segun haga falta (si hay cursor personalizado se usa ese)
	local function MakeCrosshair(visible)
		local gui = Instance.new("ScreenGui")
		gui.Name = "ShiftLockCrosshairGui"
		gui.IgnoreGuiInset = true
		gui.ResetOnSpawn = false
		gui.DisplayOrder = 1
		if syn and syn.protect_gui then
			pcall(syn.protect_gui, gui)
		end
		gui.Parent = guiParent

		local cross = Instance.new("ImageLabel")
		cross.Name = "Crosshair"
		cross.Size = UDim2.fromOffset(32, 32)
		cross.AnchorPoint = Vector2.new(0.5, 0.5)
		cross.Position = UDim2.fromScale(0.5, 0.5)
		cross.BackgroundTransparency = 1
		cross.Image = "rbxasset://textures/MouseLockedCursor.png"
		cross.Visible = visible
		cross.Parent = gui
		ShiftLock.Crosshair = cross
	end

	local function DropCrosshair()
		if ShiftLock.Crosshair then
			ShiftLock.Crosshair.Parent:Destroy()
			ShiftLock.Crosshair = nil
		end
	end

	-- Si se quita el shiftlock con el menu abierto, el cursor no se puede devolver en ese momento
	-- (la libreria lo maneja) y podia quedar escondido al cerrar el menu. Se espera a que cierres el
	-- menu y ahi se devuelve. Solo corre un aviso a la vez y termina solo.
	local iconWaiting = false
	local function RestoreIconAfterMenu()
		if iconWaiting then
			return
		end
		iconWaiting = true
		task.spawn(function()
			while Library.Toggled == true and Library.Unloaded ~= true and not ShiftLock.Active do
				task.wait(0.25)
			end
			iconWaiting = false
			task.wait(0.1)
			if
				not ShiftLock.Active
				and Library.Unloaded ~= true
				and UserInputService.MouseEnabled
				and not (CursorCrosshair and CursorCrosshair.Gui)
			then
				UserInputService.MouseIconEnabled = true
			end
		end)
	end

	local function OnRender()
		local menuOpen = Library.Toggled == true
		if not UserInputService.MouseEnabled then
			-- Movil: solo gira el personaje con la camara
			FaceCamera()
			return
		end
		if menuOpen or UserInputService:GetFocusedTextBox() or UserInputService:IsKeyDown(FREE_KEY) then
			if UserInputService.MouseBehavior ~= DefaultMouse then
				UserInputService.MouseBehavior = DefaultMouse
			end
			SetAutoRotate(true)
			-- Con el menu abierto el cursor lo maneja la libreria
			if not menuOpen and not UserInputService.MouseIconEnabled and not (CursorCrosshair and CursorCrosshair.Gui) then
				UserInputService.MouseIconEnabled = true
			end
			if ShiftLock.Locked then
				ShiftLock.Locked = false
				if ShiftLock.Crosshair then
					ShiftLock.Crosshair.Visible = false
				end
			end
			return
		end

		if UserInputService.MouseBehavior ~= LockCenter then
			UserInputService.MouseBehavior = LockCenter
		end
		if UserInputService.MouseIconEnabled then
			UserInputService.MouseIconEnabled = false
		end
		if not ShiftLock.Locked then
			ShiftLock.Locked = true
			if ShiftLock.Crosshair then
				ShiftLock.Crosshair.Visible = true
			end
		end
		-- Si se prende el cursor personalizado se quita la mira de shiftlock (no quedan dos);
		-- si se apaga, vuelve la mira de shiftlock (antes se quedaba sin ninguna mira)
		if CursorCrosshair and CursorCrosshair.Gui then
			if ShiftLock.Crosshair then
				DropCrosshair()
			end
		elseif not ShiftLock.Crosshair then
			MakeCrosshair(true)
		end
		FaceCamera()
	end

	-- Pone el shiftlock de verdad
	function ShiftLock.Engage()
		if ShiftLock.Active then
			return
		end
		ShiftLock.Active = true
		-- Rotacion base: solo se guarda si NO es CameraRelative, asi prender/apagar muy rapido
		-- nunca puede dejar guardado el valor del shiftlock como si fuera el original
		if GameSettings.RotationType ~= CameraRelative then
			ShiftLock.OrigRot = GameSettings.RotationType
		elseif ShiftLock.OrigRot == nil then
			ShiftLock.OrigRot = Enum.RotationType.MovementRelative
		end
		ShiftLock.OrigIcon = UserInputService.MouseIconEnabled

		ApplyRotation()
		ShiftLock.RotConn = GameSettings:GetPropertyChangedSignal("RotationType"):Connect(QueueRotation)
		-- Al reaparecer se vuelve a aplicar
		ShiftLock.CharConn = player.CharacterAdded:Connect(function()
			task.defer(ApplyRotation)
		end)

		if UserInputService.MouseEnabled then
			-- Si ya hay un cursor personalizado (CursorCrosshair) se usa ese; si no, se dibuja una mira
			if not ShiftLock.Crosshair and not (CursorCrosshair and CursorCrosshair.Gui) then
				MakeCrosshair(false)
			end
		end
		-- RenderStepped corre ANTES que el script de camara de Roblox: asi la camara ya ve el mouse
		-- en LockCenter y gira con solo moverlo (igual que el script de referencia). PC y movil.
		ShiftLock.RenderConn = RunService.RenderStepped:Connect(OnRender)
	end

	-- Quita el shiftlock y deja todo como estaba
	function ShiftLock.Release(keepCrosshair)
		if not ShiftLock.Active then
			return
		end
		ShiftLock.Active = false

		if ShiftLock.RotConn then
			ShiftLock.RotConn:Disconnect()
			ShiftLock.RotConn = nil
		end
		if ShiftLock.CharConn then
			ShiftLock.CharConn:Disconnect()
			ShiftLock.CharConn = nil
		end
		if ShiftLock.RenderConn then
			ShiftLock.RenderConn:Disconnect()
			ShiftLock.RenderConn = nil
		end
		SetAutoRotate(true)

		-- Al pausar con F la mira solo se esconde (no se destruye y se vuelve a crear en cada F);
		-- al apagar el toggle si se destruye
		if keepCrosshair then
			if ShiftLock.Crosshair then
				ShiftLock.Crosshair.Visible = false
			end
		else
			DropCrosshair()
		end
		if UserInputService.MouseEnabled then
			if UserInputService.MouseBehavior ~= DefaultMouse then
				UserInputService.MouseBehavior = DefaultMouse
			end
			-- El cursor SIEMPRE vuelve (antes podia quedar escondido si se prendio con el menu abierto).
			-- Si hay cursor personalizado (CursorCrosshair) ese se encarga de esconder el del sistema.
			if not (CursorCrosshair and CursorCrosshair.Gui) then
				if Library.Toggled ~= true then
					if not UserInputService.MouseIconEnabled then
						UserInputService.MouseIconEnabled = true
					end
				else
					RestoreIconAfterMenu()
				end
			end
		end
		ShiftLock.Locked = false

		-- RotationType es una configuracion del usuario (escribirla es caro): solo se escribe si cambia
		local rotTarget = Enum.RotationType.MovementRelative
		if ShiftLock.OrigRot and ShiftLock.OrigRot ~= CameraRelative then
			rotTarget = ShiftLock.OrigRot
		end
		if GameSettings.RotationType ~= rotTarget then
			GameSettings.RotationType = rotTarget
		end
	end

	-- Pausa / reanuda el shiftlock (keybind, tecla C o boton en pantalla). Solo si esta prendido.
	function ShiftLock.ToggleLock()
		if not ShiftLock.Enabled then
			return false
		end
		if ShiftLock.Active then
			ShiftLock.Release(true)
		else
			ShiftLock.Engage()
		end
		ShiftLock.Refresh()
		return true
	end

	-- Tecla C: solo cuando NO hay keybind configurada
	local function OnInput(input, gp)
		if gp or input.KeyCode ~= DEFAULT_KEY or Library.Toggled == true then
			return
		end
		local picker = Library.Options.AdvancedShiftlockKey
		local key = picker and picker.Value
		if key == nil or key == "None" then
			ShiftLock.ToggleLock()
		end
	end

	function ShiftLock.Enable()
		if ShiftLock.Enabled then
			return
		end
		ShiftLock.Enabled = true
		ShiftLock.Engage()
		ShiftLock.InputConn = UserInputService.InputBegan:Connect(OnInput)
	end

	function ShiftLock.Disable()
		if not ShiftLock.Enabled then
			return
		end
		ShiftLock.Enabled = false
		if ShiftLock.InputConn then
			ShiftLock.InputConn:Disconnect()
			ShiftLock.InputConn = nil
		end
		ShiftLock.Release()
		DropCrosshair()
	end

	-- Boton en pantalla (para movil). Se crea una vez, oculto, sin bucles.
	local BtnGui = Instance.new("ScreenGui")
	BtnGui.Name = "ShiftLockButtonGui"
	BtnGui.IgnoreGuiInset = true
	BtnGui.ResetOnSpawn = false
	BtnGui.DisplayOrder = 1
	if syn and syn.protect_gui then
		pcall(syn.protect_gui, BtnGui)
	end
	BtnGui.Parent = guiParent

	-- Es un TextButton (no un Frame) para que el arrastre y el click funcionen sobre el mismo objeto
	local BtnFrame = Instance.new("TextButton")
	BtnFrame.Name = "ShiftLockButton"
	BtnFrame.Text = ""
	BtnFrame.AutoButtonColor = false
	BtnFrame.Size = UDim2.fromOffset(52, 52)
	BtnFrame.AnchorPoint = Vector2.new(1, 0)
	BtnFrame.Position = UDim2.new(1, -16, 0, 52)
	BtnFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	BtnFrame.BackgroundTransparency = 0.45
	BtnFrame.BorderSizePixel = 0
	BtnFrame.Visible = false
	BtnFrame.Parent = BtnGui

	Instance.new("UICorner", BtnFrame).CornerRadius = UDim.new(1, 0)

	local BtnStroke = Instance.new("UIStroke", BtnFrame)
	BtnStroke.Thickness = 2
	BtnStroke.Transparency = 0.3
	BtnStroke.Color = COL_OFF

	local BtnIcon = Instance.new("ImageLabel", BtnFrame)
	BtnIcon.Size = UDim2.fromScale(0.62, 0.62)
	BtnIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	BtnIcon.Position = UDim2.fromScale(0.5, 0.5)
	BtnIcon.BackgroundTransparency = 1
	BtnIcon.Image = "rbxasset://textures/MouseLockedCursor.png"
	BtnIcon.ImageColor3 = COL_OFF
	BtnIcon.ScaleType = Enum.ScaleType.Fit

	local Btn = BtnFrame
	local BtnDrag = DragGui(BtnFrame)

	function ShiftLock.Refresh()
		local on = ShiftLock.Active
		BtnIcon.ImageColor3 = on and COL_ON or COL_OFF
		BtnStroke.Color = on and COL_ON or COL_OFF
		BtnFrame.BackgroundTransparency = on and 0.2 or 0.45
	end

	Btn.MouseButton1Click:Connect(function()
		if BtnDrag.Moved then
			return
		end
		-- No sirve si el Shiftlock no esta prendido
		if not ShiftLock.ToggleLock() then
			Library:Notify("Prende el Shiftlock", 2)
		end
	end)

	AdvancedTab:AddToggle("AdvancedShiftlock", {
		Text = "Shiftlock",
		Default = false,
		Callback = function(Value)
			if Value then
				ShiftLock.Enable()
			else
				ShiftLock.Disable()
			end
			ShiftLock.Refresh()
		end,
	}):AddKeyPicker("AdvancedShiftlockKey", {
		Default = "C",
		SyncToggleState = false,
		Mode = "Toggle",
		Text = "Shiftlock",
		NoUI = false,
	})

	-- Keybind configurada (por defecto C): pausa / reanuda el shiftlock (si no hay keybind, se usa la tecla C)
	Library.Options.AdvancedShiftlockKey:OnClick(function()
		ShiftLock.ToggleLock()
	end)

	AdvancedTab:AddToggle("AdvancedShiftlockOnScreen", {
		Text = "Show Shiftlock On Screen",
		Default = false,
		Callback = function(Value)
			BtnFrame.Visible = Value
			ShiftLock.Refresh()
		end,
	})

	pcall(function()
		Library:OnUnload(function()
			ShiftLock.Disable()
			BtnGui:Destroy()
		end)
	end)
end

-- ============================================================
-- ADVANCED > Thirdp (apagado por defecto)
-- Mientras eres Beast el juego te bloquea el zoom en primera persona. Con Thirdp prendido NO te
-- saca de primera persona: solo te quita ese bloqueo para que alejes el zoom TU (rueda del mouse)
-- si quieres tercera persona.
--   * Se pone solo cada vez que te vuelves Beast (como correr el comando thirdp de Infinite Yield,
--     pero sin tener que hacerlo a mano). Escribe una sola vez y, durante ENFORCE_WINDOW segundos,
--     si el juego vuelve a bloquear el zoom se quita solo (por eventos). Pasada la ventana queda
--     con 0 conexiones y 0 trabajo (sin bucles ni lag).
--   * Si lo apagas mientras sigues siendo Beast NO se revierte; la camara vuelve a como estaba
--     solo cuando dejas de ser Beast.
--   * Si no eres Beast no toca nada (queda armada y se pone cuando seas Beast).
-- ============================================================
Thirdp = {
	Wanted = false, -- toggle prendido
	Applied = false, -- zoom desbloqueado puesto ahora mismo
	Orig = nil,
	Conns = {},
}

do
	local ThirdMode = Enum.CameraMode.Classic
	-- Zoom maximo fijo en 9 studs (ya no hay slider: no se lee ninguna opcion en cada correccion)
	local THIRD_MIN = 0.5
	local THIRD_MAX = 9
	local busy = false
	local enforcePending = false
	-- Tope de correcciones: como maximo 1 cada ENFORCE_GAP segundos. Si el juego pelea con esto
	-- (pone el zoom/modo cada frame), sin tope se escribia la camara 2 veces por frame y la camara de
	-- Roblox recalculaba cada vez = lag. Con el tope eso nunca pasa de 5 escrituras por segundo.
	local ENFORCE_GAP = 0.2
	local lastEnforce = 0
	-- Segundos que se vigila el bloqueo del juego despues de volverte Beast (luego 0 conexiones).
	-- Si el juego te vuelve a bloquear el zoom pasado ese tiempo, sube este valor.
	local ENFORCE_WINDOW = 5
	local windowToken = 0

	-- Misma deteccion que el ESP: tu personaje tiene "BeastPowers"
	local function IsBeast()
		return BeastWatch.IsBeast()
	end

	local function EnforceNow()
		enforcePending = false
		lastEnforce = os.clock()
		if busy or not Thirdp.Applied then
			return
		end
		busy = true
		-- Si el juego cambia el modo o el zoom maximo mientras esta puesta la tercera persona, se anota
		-- lo que queria el juego para devolverlo al final (antes se devolvia el valor viejo y podia
		-- quedarse en primera persona al dejar de ser Beast)
		local o = Thirdp.Orig
		if player.CameraMode ~= ThirdMode then
			if o then
				o.Mode = player.CameraMode
			end
			player.CameraMode = ThirdMode
		end
		if player.CameraMaxZoomDistance ~= THIRD_MAX then
			if o then
				o.Max = player.CameraMaxZoomDistance
			end
			player.CameraMaxZoomDistance = THIRD_MAX
		end
		if player.CameraMinZoomDistance > THIRD_MIN then
			player.CameraMinZoomDistance = THIRD_MIN
		end
		busy = false
	end

	-- Los 3 eventos (modo, zoom max, zoom min) pueden llegar juntos: se corrige UNA sola vez
	-- (en el mismo frame si hace rato que no se corrige; si no, cuando se cumpla ENFORCE_GAP)
	local function Enforce()
		if enforcePending then
			return
		end
		enforcePending = true
		local wait = ENFORCE_GAP - (os.clock() - lastEnforce)
		if wait > 0 then
			task.delay(wait, EnforceNow)
		else
			task.defer(EnforceNow)
		end
	end

	local function DisconnectAll(list)
		for i = #list, 1, -1 do
			list[i]:Disconnect()
			list[i] = nil
		end
	end

	local function Apply()
		if Thirdp.Applied then
			return
		end
		Thirdp.Applied = true
		Thirdp.Orig = {
			Mode = player.CameraMode,
			Max = player.CameraMaxZoomDistance,
			Min = player.CameraMinZoomDistance,
		}
		-- NO te saca de primera persona (el zoom se queda donde esta): solo quita el bloqueo del zoom
		-- para que puedas alejarlo tu con la rueda del mouse
		-- Igual que el comando thirdp de Infinite Yield: se escribe UNA vez, y solo lo que haga falta
		busy = true
		if player.CameraMode ~= ThirdMode then
			player.CameraMode = ThirdMode
		end
		if player.CameraMaxZoomDistance ~= THIRD_MAX then
			player.CameraMaxZoomDistance = THIRD_MAX
		end
		if player.CameraMinZoomDistance > THIRD_MIN then
			player.CameraMinZoomDistance = THIRD_MIN
		end
		busy = false
		-- Al volverte Beast el juego pone su bloqueo un instante DESPUES de que aparece BeastPowers
		-- (por eso el comando de Infinite Yield hay que correrlo a mano). Por eso, solo durante
		-- ENFORCE_WINDOW segundos, si el juego lo revierte se vuelve a poner (por eventos). Pasada la
		-- ventana se desconecta TODO: 0 conexiones y 0 trabajo, como el comando de Infinite Yield.
		-- Cada vez que vuelves a ser Beast se arma otra ventana sola. (math.huge = vigilar siempre)
		table.insert(Thirdp.Conns, player:GetPropertyChangedSignal("CameraMode"):Connect(Enforce))
		table.insert(Thirdp.Conns, player:GetPropertyChangedSignal("CameraMaxZoomDistance"):Connect(Enforce))
		table.insert(Thirdp.Conns, player:GetPropertyChangedSignal("CameraMinZoomDistance"):Connect(Enforce))
		windowToken = windowToken + 1
		local myWindow = windowToken
		if ENFORCE_WINDOW ~= math.huge then
			task.delay(ENFORCE_WINDOW, function()
				if myWindow == windowToken and Thirdp.Applied then
					DisconnectAll(Thirdp.Conns)
				end
			end)
		end
	end

	local function Restore()
		if not Thirdp.Applied then
			return
		end
		Thirdp.Applied = false
		DisconnectAll(Thirdp.Conns)
		local o = Thirdp.Orig
		Thirdp.Orig = nil
		if o then
			busy = true
			player.CameraMinZoomDistance = o.Min
			player.CameraMaxZoomDistance = o.Max
			player.CameraMode = o.Mode
			busy = false
		end
	end

	local function Cleanup()
		Restore()
		BeastWatch.Unsubscribe("Thirdp")
	end

	local function Evaluate()
		local beast = IsBeast()
		if beast then
			if Thirdp.Wanted then
				Apply()
			end
			-- Apagada pero siendo Beast: se queda puesta hasta que dejes de serlo
		else
			Restore()
			if not Thirdp.Wanted then
				Cleanup()
			end
		end
	end

	function Thirdp.Enable()
		Thirdp.Wanted = true
		BeastWatch.Subscribe("Thirdp", Evaluate)
		Evaluate()
	end

	function Thirdp.Disable()
		Thirdp.Wanted = false
		if Thirdp.Applied and IsBeast() then
			Library:Notify("Thirdp: se quitara cuando dejes de ser Beast", 3)
		else
			Cleanup()
		end
	end

	AdvancedTab:AddToggle("AdvancedThirdp", {
		Text = "Thirdp",
		Default = false,
		Callback = function(Value)
			if Value then
				Thirdp.Enable()
			else
				Thirdp.Disable()
			end
		end,
	})

	pcall(function()
		Library:OnUnload(function()
			Thirdp.Wanted = false
			Cleanup()
		end)
	end)
end

ShaderTab = Tabs["General Customization"]:AddRightTabbox("Shaders")
ShaderSettings1 = ShaderTab:AddTab("Shader Presets")

ShaderSettings1:AddToggle("EnableShaders", {
	Text = "Enable Shaders",
	Default = false,
	Callback = function(Value)
		ShaderSettings.Enabled = Value
		ApplyShaderLighting()
	end,
})

ShaderSettings1:AddDropdown("ShaderPreset", {
	Values = { "Default", "Morning", "Midday", "Afternoon", "Evening", "Night", "Midnight" },
	Default = "Default",
	Text = "Shader Preset",
	Callback = function(Value)
		local presets = LoadShaderPresets()
		ShaderIsDefault = (Value == "Default")
		if Value == "Default" then
			shaderlight = {
				["yfbghj"] = backupLighting.Ambient,
				["tgvbyd"] = backupLighting.ClockTime,
				["ghuybhuyhj"] = backupLighting.GeographicLatitude,
				["khnbfth"] = backupLighting.Brightness,
				["hgyghkg"] = backupLighting.ColorShift_Bottom,
				["yfbhjku"] = backupLighting.ColorShift_Top,
				["ygyyfgvhbjytrt"] = backupLighting.EnvironmentDiffuseScale,
				["sdfcddc"] = backupLighting.EnvironmentSpecularScale,
				["hgnujuu7thgr"] = backupLighting.GlobalShadows,
				["hyhnngtf"] = backupLighting.OutdoorAmbient,
				["hdfr7thgr"] = backupLighting.ExposureCompensation,
				["fhnchvhfjsd"] = 0,
				["ugtbbjhygt"] = 0,
				["tfbghuugbnjhg"] = 0,
				["fvrtccvghghj"] = Color3.fromRGB(255, 255, 255),
				["jnfdhbnfcvh"] = 0.4,
				["fvtyghj"] = 24,
				["ygbhnj"] = 0.95,
				["njnfg"] = 0,
				["jdfkd"] = 0.1,
				["fvgsdfg"] = 50,
				["sdkvkflv"] = 10,
				["hbjhd"] = 0.75,
				["gyhgtg"] = 0,
				["ygbhggv"] = 0,
				["jghbjhgyfd"] = Color3.fromRGB(255, 255, 255),
				["shdbsnjfc"] = 0,
				["skdjfkdm"] = 0,
				["sjdjncdjf"] = Color3.fromRGB(199, 199, 199),
				["efjdjfk"] = Color3.fromRGB(106, 112, 125),
				["sejfd"] = 0,
				["jddfjsd"] = 0,
			}
		else
			shaderlight = presets[Value:lower()]
		end
		ApplyShaderLighting()
	end,
})

ShaderSettings1:AddDivider()

-- ============================================================
-- BOOST GAME (script FPS Optimizer: reduce procesamiento grafico innecesario)
-- Hace exactamente lo del script original; al apagarlo restaura los valores anteriores.
-- ============================================================
BoostGame = { Saved = nil, Conns = {}, Pending = false, Last = 0 }

-- ============================================================
-- Boost Game se mantiene actualizado por EVENTOS (sin bucles, sin Heartbeat):
--   * Lighting.ChildAdded: efecto o atmosfera nueva -> se apaga/pone en 0 al instante
--   * cambia GlobalShadows / FogEnd / un efecto / la densidad -> se vuelve a corregir
-- Las correcciones se juntan en UNA sola y como maximo 1 cada BOOST_GAP segundos, y solo se escribe
-- lo que de verdad cambio. Asi, aunque el juego pelee con esto, nunca pasa de 4 correcciones por
-- segundo (sin tope podia escribir Lighting varias veces por frame = lag).
-- Al apagarlo se desconecta todo y se restauran los valores anteriores.
-- ============================================================
local BOOST_GAP = 0.25
local BoostReapply

-- Apaga solo efectos pesados de Lighting. Cada instancia va en su propio pcall:
-- Atmosphere y Sky no tienen "Enabled", asi que antes el error cortaba todo el proceso a la mitad.
-- Effects es de claves debiles: si el juego destruye un efecto, Lua lo libera solo
-- (antes se guardaba para siempre y la memoria crecia = bajaba FPS / lag en partidas largas).
local function BoostEffect(saved, child)
	if saved.Effects[child] then
		return
	end
	if child:IsA("PostEffect") then
		pcall(function()
			saved.Effects[child] = { "Enabled", child.Enabled }
			child.Enabled = false
		end)
	elseif child:IsA("Atmosphere") then
		pcall(function()
			saved.Effects[child] = { "Density", child.Density }
			child.Density = 0
		end)
	else
		return
	end
	-- Si el juego lo vuelve a prender / cambiar, se corrige (por evento, con tope)
	table.insert(BoostGame.Conns, child.Changed:Connect(BoostReapply))
end

-- Solo escribe lo que cambio
local function BoostApply(saved)
	if Lighting.GlobalShadows then
		Lighting.GlobalShadows = false
	end
	if Lighting.FogEnd < 1e9 then
		Lighting.FogEnd = 9e9
	end
	for _, child in ipairs(Lighting:GetChildren()) do
		if saved.Effects[child] == nil then
			BoostEffect(saved, child)
		elseif child:IsA("PostEffect") then
			if child.Enabled then
				child.Enabled = false
			end
		elseif child:IsA("Atmosphere") then
			if child.Density ~= 0 then
				child.Density = 0
			end
		end
	end
end

BoostReapply = function()
	if BoostGame.Pending or not BoostGame.Saved then
		return
	end
	BoostGame.Pending = true
	local function run()
		BoostGame.Pending = false
		BoostGame.Last = os.clock()
		local saved = BoostGame.Saved
		if saved then
			pcall(BoostApply, saved)
		end
	end
	local wait = BOOST_GAP - (os.clock() - BoostGame.Last)
	if wait > 0 then
		task.delay(wait, run)
	else
		task.defer(run)
	end
end

function StartBoostGame()
	if BoostGame.Saved then
		return
	end
	local saved = {
		Shadows = Lighting.GlobalShadows,
		FogEnd = Lighting.FogEnd,
		Effects = setmetatable({}, { __mode = "k" }),
	}
	BoostGame.Saved = saved

	pcall(BoostApply, saved)

	table.insert(BoostGame.Conns, Lighting.ChildAdded:Connect(function(child)
		if BoostGame.Saved then
			BoostEffect(BoostGame.Saved, child)
		end
	end))
	table.insert(BoostGame.Conns, Lighting:GetPropertyChangedSignal("GlobalShadows"):Connect(BoostReapply))
	table.insert(BoostGame.Conns, Lighting:GetPropertyChangedSignal("FogEnd"):Connect(BoostReapply))
end

function StopBoostGame()
	local saved = BoostGame.Saved
	if not saved then
		return
	end
	BoostGame.Saved = nil
	for i = #BoostGame.Conns, 1, -1 do
		BoostGame.Conns[i]:Disconnect()
		BoostGame.Conns[i] = nil
	end
	pcall(function()
		Lighting.GlobalShadows = saved.Shadows
		Lighting.FogEnd = saved.FogEnd
	end)
	for inst, entry in pairs(saved.Effects) do
		pcall(function()
			if inst.Parent then
				inst[entry[1]] = entry[2]
			end
		end)
	end
end

ShaderSettings1:AddToggle("BoostGame", {
	Text = "Boost Game",
	Default = false,
	Callback = function(Value)
		if Value then
			StartBoostGame()
		else
			StopBoostGame()
			-- Al soltar Boost Game, Color Correction / Bloom vuelven a su estado segun sus toggles
			ApplyShaderEffects()
		end
	end,
})

ShaderSettings1:AddToggle("ColorCorrection", {
	Text = "Color Correction",
	Default = false,
	Callback = function(Value)
		shaderWL["cor"] = Value
		ApplyShaderEffects()
	end,
})

ShaderSettings1:AddToggle("Bloom", {
	Text = "Bloom Effect",
	Default = false,
	Callback = function(Value)
		shaderWL["bl"] = Value
		ApplyShaderEffects()
	end,
})

conn17 = player.CharacterAdded:Connect(function(character)
	character:WaitForChild("HumanoidRootPart")
	task.wait(0.5)
	if FlopSettings.Enabled then
		StartFlopHelper()
	end
end)

task.spawn(function()
	local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu", "wrench")
	MenuGroup:AddToggle("KeybindMenuOpen", {
		Default = Library.KeybindFrame.Visible,
		Text = "Open Keybind Menu",
		Callback = function(value)
			Library.KeybindFrame.Visible = value
		end,
	})
	MenuGroup:AddToggle("ShowCustomCursor", {
		Text = "Custom Cursor",
		Default = true,
		Callback = function(Value)
			Library.ShowCustomCursor = Value
		end,
	})
	MenuGroup:AddDropdown("NotificationSide", {
		Values = { "Left", "Right" },
		Default = "Right",
		Text = "Notification Side",
		Callback = function(Value)
			Library:SetNotifySide(Value)
		end,
	})
	MenuGroup:AddDropdown("DPIDropdown", {
		Values = { "50%", "75%", "90%", "100%", "125%", "150%", "175%" },
		Default = "90%",
		Text = "DPI Scale",
		Callback = function(Value)
			Value = Value:gsub("%%", "")
			local DPI = tonumber(Value)
			Library:SetDPIScale(DPI)
		end,
	})
	MenuGroup:AddDivider()
	MenuGroup:AddLabel("Menu bind")
		:AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })

	local ExtraGroup = Tabs["UI Settings"]:AddRightGroupbox("Extra")

	ExtraGroup:AddToggle("ExecuteInfiniteYieldToggle", {
		Text = "Execute Infinite Yield",
		Default = false,
		Callback = function(Value)
			if not Value then
				return
			end

			local ok, err = pcall(function()
				local source = game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source")
				if type(source) ~= "string" or #source == 0 then
					error("respuesta vacia al descargar Infinite Yield")
				end
				local chunk, compileError = loadstring(source)
				if type(chunk) ~= "function" then
					error("no se pudo compilar Infinite Yield: " .. tostring(compileError))
				end
				chunk()
			end)

			if not ok then
				warn("[FTFX] No se pudo ejecutar Infinite Yield: " .. tostring(err))
				Library:Notify("No se pudo cargar Infinite Yield. Revisa la conexion.", 4)
			end
		end,
	})

	Library.ToggleKeybind = Options.MenuKeybind

	ThemeManager:SetLibrary(Library)
	SaveManager:SetLibrary(Library)
	SaveManager:IgnoreThemeSettings()
	SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
	ThemeManager:SetFolder("FTFX")
	SaveManager:SetFolder("FTFX/FTF")
	SaveManager:BuildConfigSection(Tabs["UI Settings"])
	ThemeManager:ApplyToTab(Tabs["UI Settings"])

	-- FPS Manager
	FPSSettings = {
		HighFPS = 240,
		LowFPS = 60,
		IsLowFPS = false,
		LastFrameTime = os.clock(),
	}

	if CoreGui:FindFirstChild("FPSMobileButtonGui") then
		CoreGui.FPSMobileButtonGui:Destroy()
	end

	FPSMobileGui = Instance.new("ScreenGui")
	FPSMobileGui.Name = "FPSMobileButtonGui"
	FPSMobileGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	if syn and syn.protect_gui then
		pcall(syn.protect_gui, FPSMobileGui)
	end
	FPSMobileGui.Parent = CoreGui

	FPSPhysicalButton = Instance.new("TextButton")
	FPSPhysicalButton.Name = "FPSButton"
	FPSPhysicalButton.Parent = FPSMobileGui
	FPSPhysicalButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	FPSPhysicalButton.BackgroundTransparency = 0.2
	FPSPhysicalButton.Position = UDim2.new(0, 20, 1, -80)
	FPSPhysicalButton.Size = UDim2.new(0, 120, 0, 45)
	FPSPhysicalButton.Font = Enum.Font.GothamBold
	FPSPhysicalButton.Text = "FPS: HIGH"
	FPSPhysicalButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	FPSPhysicalButton.TextSize = 16
	FPSPhysicalButton.Visible = false

	FPSButtonUICorner = Instance.new("UICorner")
	FPSButtonUICorner.CornerRadius = UDim.new(0, 8)
	FPSButtonUICorner.Parent = FPSPhysicalButton

	FPSButtonUIStroke = Instance.new("UIStroke")
	FPSButtonUIStroke.Color = Color3.fromRGB(60, 200, 60)
	FPSButtonUIStroke.Thickness = 2
	FPSButtonUIStroke.Parent = FPSPhysicalButton

	FPSDrag = DragGui(FPSPhysicalButton)

	local function ApplyFPSCap()
		local targetFPS = FPSSettings.IsLowFPS and FPSSettings.LowFPS or FPSSettings.HighFPS
		if type(setfpscap) == "function" then
			pcall(setfpscap, targetFPS)
		elseif type(set_fps_cap) == "function" then
			pcall(set_fps_cap, targetFPS)
		end
	end

	function UpdateFPSToggleState()
		ApplyFPSCap()
		if FPSSettings.IsLowFPS then
			FPSPhysicalButton.Text = "FPS: LOW"
			FPSButtonUIStroke.Color = Color3.fromRGB(200, 60, 60)
			Library:Notify("Switched to LOW: " .. FPSSettings.LowFPS .. " FPS", 1)
		else
			FPSPhysicalButton.Text = "FPS: HIGH"
			FPSButtonUIStroke.Color = Color3.fromRGB(60, 200, 60)
			Library:Notify("Switched to HIGH: " .. FPSSettings.HighFPS .. " FPS", 1)
		end
	end

	FPSPhysicalButton.MouseButton1Click:Connect(function()
		if FPSDrag.Moved then
			return
		end
		FPSSettings.IsLowFPS = not FPSSettings.IsLowFPS
		UpdateFPSToggleState()
	end)

	Groupboxes.Gadgets.OtherGadgets:AddToggle("FPSPhysicalButtonToggle", {
		Text = "Show Physical FPS Button",
		Default = false,
		Callback = function(Value)
			FPSPhysicalButton.Visible = Value
		end,
	})

	Groupboxes.Gadgets.OtherGadgets:AddSlider("FPSHighSlider", {
		Text = "High FPS",
		Default = 240,
		Min = 60,
		Max = 360,
		Rounding = 0,
		Compact = false,
		Callback = function(Value)
			FPSSettings.HighFPS = Value
			if not FPSSettings.IsLowFPS then
				UpdateFPSToggleState()
			end
		end,
	})

	Groupboxes.Gadgets.OtherGadgets:AddSlider("FPSLowSlider", {
		Text = "Low FPS",
		Default = 60,
		Min = 15,
		Max = 120,
		Rounding = 0,
		Compact = false,
		Callback = function(Value)
			FPSSettings.LowFPS = Value
			if FPSSettings.IsLowFPS then
				UpdateFPSToggleState()
			end
		end,
	})

	Groupboxes.Gadgets.OtherGadgets:AddLabel("FPS Toggle Keybind"):AddKeyPicker("FPSToggleKey", {
		Default = "LeftControl",
		SyncToggleState = false,
		Mode = "Toggle",
		Text = "FPS Toggle Keybind",
		NoUI = false,
	})

	Options.FPSToggleKey:OnClick(function()
		FPSSettings.IsLowFPS = not FPSSettings.IsLowFPS
		UpdateFPSToggleState()
	end)

	ApplyFPSCap()

	SaveManager:LoadAutoloadConfig()
end)
